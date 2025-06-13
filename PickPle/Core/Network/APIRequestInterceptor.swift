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
                    print("❌ retrieveAndDecryptToken Fail - \(failure)")
                    completion(.failure(failure))
                }
            }
            return
        }
        
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: any Error, completion: @escaping (RetryResult) -> Void) {
        
        // 리프레시 토큰 만료
        guard let response = request.response, response.statusCode != 418 else {
            print("retry:: 리프레시 토큰 만료, URL : \(request.request?.url?.absoluteString)")
            completion(.doNotRetryWithError(NetworkError.expired))
            return
        }
        
        // 액세스 토큰 만료
        guard let response = request.response, response.statusCode == 419 else {
            print("retry:: 액세스 토큰 만료 아님")
            completion(.doNotRetryWithError(error))
            return
        }
        
        print("retry:: 엑세스 토큰 갱신 로직 시작")
        
        lock.lock()
        defer { lock.unlock() }
        print("retry:: 락")
        print("class 주소", Unmanaged.passUnretained(self).toOpaque())
        requestForRetry.append(completion)
        
        if !isRefreshing {
            print("retry:: isRefreshing 내부 시작")
            isRefreshing = true
            
            // 여기서 lock을 해제하고 refresh 호출
            print("retry:: refresh 호출 전 락 해제")
            SecureTokenManager.shared.retrieveAndDecryptTokens(forKeys: (SecureKey.ACCESS_TOKEN, SecureKey.REFRESH_TOKEN)) { [weak self] result in
                guard let self else { return }
                
                switch result {
                case .success(let tokens):
                    print("✨ refresh token 복호화 성공, refresh API 호출")
                    lock.lock()
                    
                    Task { [weak self] in
                        guard let self else { return }
                        
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        
                        let request = AF.request(AuthRouter.refresh(tokens.accessToken, tokens.refreshToken))
                            .validate(statusCode: 200...299)
                            .serializingDecodable(RefreshResponse.self, decoder: decoder)
                        do {
                            let value = try await request.value
                            print("✨ retry refresh success, response : \(value)")
                            SecureTokenManager.shared.encryptAndStoreToken(token: value.refreshToken, forKey: SecureKey.REFRESH_TOKEN) { [weak self] result in
                                guard let self else { return }
                                switch result {
                                case .success:
                                    SecureTokenManager.shared.encryptAndStoreToken(token: value.accessToken, forKey: SecureKey.ACCESS_TOKEN) { [weak self] result in
                                        guard let self else { return }
                                        defer {
                                            lock.unlock()
                                            isRefreshing = false
                                            requestForRetry.removeAll()
                                        }
                                        
                                        switch result {
                                        case .success:
                                            print("✨ retry refresh 락 해제 Token store success")
                                            requestForRetry.forEach { $0(.retry) }
                                        case .failure(let error):
                                            print("✨ retry refresh 락 해제 accessToken store failure")
                                            requestForRetry.forEach { $0(.doNotRetryWithError(error)) }
                                        }
                                    }
                                case .failure(let error):
                                    print("✨ retry refresh 락 해제 refreshToken store failure")
                                    requestForRetry.forEach { $0(.doNotRetryWithError(error)) }
                                    lock.unlock()
                                    isRefreshing = false
                                    requestForRetry.removeAll()
                                }
                            }
                        } catch {
                            print("✨ retry refresh 락 해제 error catch:: \(error)")
                            let error = NetworkError.expired
                            requestForRetry.forEach { $0(.doNotRetryWithError(error)) }
                            
                            lock.unlock()
                            isRefreshing = false
                            requestForRetry.removeAll()
                        }
                    }
                case .failure:
                    print("✨ retry refresh 리프레시 토큰 복호화 실패")
                    requestForRetry.forEach {
                        $0(.doNotRetryWithError(NetworkError.expired))
                    }
                }
            }
        }
    }
}
