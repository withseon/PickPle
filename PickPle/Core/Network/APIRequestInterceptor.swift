//
//  APIRequestInterceptor.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

extension Notification.Name {
    static let forceLogoutDueToTokenFailure = Notification.Name("forceLogoutDueToTokenFailure")
}

final class APIRequestInterceptor: RequestInterceptor, @unchecked Sendable {
    private let lock = NSLock()
    private var isRefreshing = false
    private var requestForRetry: [(RetryResult) -> Void] = []
    private var tokenFailureCount = 0
    private let maxTokenFailures = 3
    
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, any Error>) -> Void) {
        print("🔗 [APIRequestInterceptor] adapt 시작 - URL: \(urlRequest.url?.absoluteString ?? "nil")")
        
        guard let url = urlRequest.url?.absoluteString else {
            print("🔗 [APIRequestInterceptor] URL이 nil이므로 그대로 진행")
            completion(.success(urlRequest))
            return
        }
        
        if url.hasPrefix(APIURL.PICKUP) {
            var urlRequest = urlRequest
            urlRequest.setValue(APIKEY.PICKUP, forHTTPHeaderField: "SesacKey")
            
            // ✅ 로그인/회원가입 요청은 토큰 없이 진행
            let authNotRequiredEndpoints = [
                "/login/kakao",
                "/login/email", 
                "/join/email",
                "/users/validation/email"
            ]
            
            let requiresAuth = !authNotRequiredEndpoints.contains { url.contains($0) }
            
            if !requiresAuth {
                print("🔗 [APIRequestInterceptor] 인증 불필요 요청 - 토큰 없이 진행: \(url)")
                completion(.success(urlRequest))
                return
            }
            
            print("🔗 [APIRequestInterceptor] PICKUP API 요청 - 토큰 조회 시작")
            print("🔗 [APIRequestInterceptor] 현재 토큰 실패 횟수: \(tokenFailureCount)/\(maxTokenFailures)")
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // 타임아웃 처리를 위한 DispatchWorkItem
            let timeoutWorkItem = DispatchWorkItem {
                print("⏰ [APIRequestInterceptor] 토큰 조회 타임아웃 (2초) - 토큰 없이 진행")
                completion(.success(urlRequest))
            }
            
            // 2초 후 타임아웃 (더 빠른 실패 처리)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: timeoutWorkItem)
            
            SecureTokenManager.shared.retrieveAndDecryptToken(forKey: SecureKey.ACCESS_TOKEN) { result in
                let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
                print("🔗 [APIRequestInterceptor] 토큰 조회 완료 - 소요시간: \(elapsedTime)초")
                
                // 타임아웃 작업 취소
                timeoutWorkItem.cancel()
                
                switch result {
                case .success(let success):
                    print("✅ [APIRequestInterceptor] 토큰 조회 성공: \(success.prefix(10))...")
                    // 성공 시 실패 카운트 리셋
                    self.tokenFailureCount = 0
                    urlRequest.setValue(success, forHTTPHeaderField: "Authorization")
                    completion(.success(urlRequest))
                case .failure(let failure):
                    print("❌ [APIRequestInterceptor] 토큰 조회 실패: \(failure)")
                    self.tokenFailureCount += 1
                    print("🔴 [APIRequestInterceptor] 토큰 실패 횟수: \(self.tokenFailureCount)/\(self.maxTokenFailures)")
                    
                    if self.tokenFailureCount >= self.maxTokenFailures {
                        print("🚨 [APIRequestInterceptor] 토큰 실패 한계 도달 - 메모리 캐시 초기화 및 강제 로그아웃 알림 발송")
                        // ✅ 토큰 캐시 초기화 (잘못된 캐시 데이터 제거)
                        SecureTokenManager.shared.clearTokenCache()
                        NotificationCenter.default.post(name: .forceLogoutDueToTokenFailure, object: nil)
                        self.tokenFailureCount = 0 // 리셋
                        // ❌ 토큰 없이 요청을 보내면 안됨
                        completion(.failure(NetworkError.expired))
                        return
                    }
                    
                    // ✅ 토큰 조회 실패 시에도 일단 요청은 진행 (서버에서 401 처리)
                    print("⚠️ [APIRequestInterceptor] 토큰 없이 요청 진행 - 서버에서 인증 실패 예상")
                    completion(.success(urlRequest))
                }
            }
            return
        }
        
        print("🔗 [APIRequestInterceptor] PICKUP API가 아님 - 그대로 진행")
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: any Error, completion: @escaping (RetryResult) -> Void) {
        
        // 리프레시 토큰 만료
        guard let response = request.response, response.statusCode != 418 else {
            print("🚨 [APIRequestInterceptor] 리프레시 토큰 만료 (418)")
            completion(.doNotRetryWithError(NetworkError.expired))
            return
        }
        
        // 액세스 토큰 만료
        guard let response = request.response, response.statusCode == 419 else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        // 요청 등록 및 갱신 여부 결정
        lock.lock()
        requestForRetry.append(completion)
        let shouldStartRefresh = !isRefreshing
        if shouldStartRefresh {
            isRefreshing = true
        }
        lock.unlock()
        
        // 필요 시 토큰 갱신
        if shouldStartRefresh {
            performTokenRefresh()
        }
    }
    
    private func performTokenRefresh() {
        SecureTokenManager.shared.retrieveAndDecryptTokens(forKeys: (SecureKey.ACCESS_TOKEN, SecureKey.REFRESH_TOKEN)) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let tokens):
                Task { [weak self] in
                    guard let self else { return }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    let request = AF.request(AuthRouter.refresh(tokens.accessToken, tokens.refreshToken))
                        .validate(statusCode: 200...299)
                        .serializingDecodable(RefreshResponse.self, decoder: decoder)
                    do {
                        let value = try await request.value
                        SecureTokenManager.shared.encryptAndStoreTokens(
                            accessToken: value.accessToken,
                            refreshToken: value.refreshToken,
                            forKeys: (SecureKey.ACCESS_TOKEN, SecureKey.REFRESH_TOKEN)
                        ) { [weak self] result in
                            guard let self else { return }
                            
                            switch result {
                            case .success:
                                print("✅ [APIRequestInterceptor] 토큰 갱신 및 저장 성공")
                                completeTokenRefresh(with: .retry)
                            case .failure(let error):
                                print("❌ [APIRequestInterceptor] 토큰 저장 실패: \(error)")
                                completeTokenRefresh(with: .doNotRetryWithError(error))
                            }
                        }
                    } catch {
                        print("🚨 [APIRequestInterceptor] 토큰 갱신 API 호출 실패")
                        let error = NetworkError.expired
                        completeTokenRefresh(with: .doNotRetryWithError(error))
                    }
                }
            case .failure:
                completeTokenRefresh(with: .doNotRetryWithError(NetworkError.expired))
            }
        }
    }
    
    // 모든 대기 중인 요청에 결과 전달
    private func completeTokenRefresh(with result: RetryResult) {
        lock.lock()
        let pendingRequests = requestForRetry
        requestForRetry.removeAll()
        isRefreshing = false
        lock.unlock()
        
        // 콜백 실행
        pendingRequests.forEach { $0(result) }
    }
}
