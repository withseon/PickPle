//
//  APIRequestInterceptor.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

final class APIRequestInterceptor: RequestInterceptor, @unchecked Sendable {
    private let lock = NSLock()
    private var isRefreshing = false
    private var requestForRetry: [(RetryResult) -> Void] = []
    
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, any Error>) -> Void) {
        guard let url = urlRequest.url?.absoluteString else {
            completion(.success(urlRequest))
            return
        }
        
        if url.hasPrefix(APIURL.PICKUP) {
            var urlRequest = urlRequest
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(APIKEY.PICKUP, forHTTPHeaderField: "SesacKey")
            
            SecureTokenManager.shared.retrieveAndDecryptToken(forKey: SecureKey.ACCESS_TOKEN) { result in
                switch result {
                case .success(let success):
                    urlRequest.setValue(success, forHTTPHeaderField: "Authorization")
                    completion(.success(urlRequest))
                case .failure(let failure):
                    print(failure)
                    completion(.success(urlRequest))
                }
            }
            return
        }
        
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: any Error, completion: @escaping (RetryResult) -> Void) {
        
        // 리프레시 토큰 만료
        guard let response = request.response, response.statusCode != 418 else {
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
                        SecureTokenManager.shared.encryptAndStoreToken(token: value.refreshToken, forKey: SecureKey.REFRESH_TOKEN) { [weak self] result in
                            guard let self else { return }
                            switch result {
                            case .success:
                                SecureTokenManager.shared.encryptAndStoreToken(token: value.accessToken, forKey: SecureKey.ACCESS_TOKEN) { [weak self] result in
                                    guard let self else { return }
                                    
                                    switch result {
                                    case .success:
                                        self.completeTokenRefresh(with: .retry)
                                    case .failure(let error):
                                        self.completeTokenRefresh(with: .doNotRetryWithError(error))
                                    }
                                }
                            case .failure(let error):
                                self.completeTokenRefresh(with: .doNotRetryWithError(error))
                            }
                        }
                    } catch {
                        let error = NetworkError.expired
                        self.completeTokenRefresh(with: .doNotRetryWithError(error))
                    }
                }
            case .failure:
                self.completeTokenRefresh(with: .doNotRetryWithError(NetworkError.expired))
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
