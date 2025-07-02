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
        
        lock.lock()
        defer { lock.unlock() }
        requestForRetry.append(completion)
        
        if !isRefreshing {
            isRefreshing = true
            
            SecureTokenManager.shared.retrieveAndDecryptTokens(forKeys: (SecureKey.ACCESS_TOKEN, SecureKey.REFRESH_TOKEN)) { [weak self] result in
                guard let self else { return }
                
                switch result {
                case .success(let tokens):
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
                                            requestForRetry.forEach { $0(.retry) }
                                        case .failure(let error):
                                            requestForRetry.forEach { $0(.doNotRetryWithError(error)) }
                                        }
                                    }
                                case .failure(let error):
                                    requestForRetry.forEach { $0(.doNotRetryWithError(error)) }
                                    lock.unlock()
                                    isRefreshing = false
                                    requestForRetry.removeAll()
                                }
                            }
                        } catch {
                            let error = NetworkError.expired
                            requestForRetry.forEach { $0(.doNotRetryWithError(error)) }
                            
                            lock.unlock()
                            isRefreshing = false
                            requestForRetry.removeAll()
                        }
                    }
                case .failure:
                    requestForRetry.forEach {
                        $0(.doNotRetryWithError(NetworkError.expired))
                    }
                }
            }
        }
    }
}
