//
//  UserRepository.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Combine

protocol UserRepository {
    func validateEmail(_ email: String) -> AnyPublisher<Result<Void, NetworkError<UserErrorResponse>>, Never>
    func signup(_ param: SignUpParam) -> AnyPublisher<Result<JoinResponse, NetworkError<UserErrorResponse>>, Never>
    func loginEmail(_ param: SignInParam) -> AnyPublisher<Result<EmailLoginResponse, NetworkError<UserErrorResponse>>, Never>
    func refresh(_ refreshToken: String, completion: @escaping (Result<Void, KeychainError>) -> Void)
}

final class DefaultUserRepository: UserRepository {
    static let shared = DefaultUserRepository()
    
    private init() { }
    
    func validateEmail(_ email: String) -> AnyPublisher<Result<Void, NetworkError<UserErrorResponse>>, Never> {
        return Future { promise in
            Task {
                do {
                    try await NetworkManager.executeFetch(
                        target: UserRouter.validateEmail(ValidationEmailRequest(email: email)),
                        responseType: ValidationEmailResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(())))
                } catch {
                    if case let NetworkError<UserErrorResponse>.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func signup(_ param: SignUpParam) -> AnyPublisher<Result<JoinResponse, NetworkError<UserErrorResponse>>, Never> {
        return Future { promise in
            Task {
                do {
                    let dto = JoinRequest(
                        email: param.email,
                        password: param.password,
                        nick: param.nickname,
                        phoneNum: param.phoneNum,
                        deviceToken: DeviceToken.value
                    )
                    let response = try await NetworkManager.executeFetch(
                        target: UserRouter.joinEmail(dto),
                        responseType: JoinResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(response)))
                } catch {
                    if case let NetworkError<UserErrorResponse>.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loginEmail(_ param: SignInParam) -> AnyPublisher<Result<EmailLoginResponse, NetworkError<UserErrorResponse>>, Never> {
        return Future { promise in
            Task {
                do {
                    let dto = EmailLoginRequest(
                        email: param.email,
                        password: param.password,
                        deviceToken: DeviceToken.value
                    )
                    let response = try await NetworkManager.executeFetch(
                        target: UserRouter.emailLogin(dto),
                        responseType: EmailLoginResponse.self,
                        errorType: UserErrorResponse.self
                    )
//                    promise(.success(.success(response)))
                    
                    SecureTokenManager.shared.encryptAndStoreToken(token: response.accessToken, forKey: SecureKey.ACCESS_TOKEN_KEY) { result in
                        switch result {
                        case .success:
                            SecureTokenManager.shared.encryptAndStoreToken(token: response.refreshToken, forKey: SecureKey.REFRESH_TOKEN_KEY) { result in
                                switch result {
                                case .success(let success):
                                    promise(.success(.success(response)))
                                case .failure(let failure):
                                    print(failure)
                                }
                            }
                        case .failure(let failure):
                            print(failure)
                        }
                    }
                    
                } catch {
                    if case let NetworkError<UserErrorResponse>.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func refresh(_ refreshToken: String, completion: @escaping (Result<Void, KeychainError>) -> Void) {
        Task {
            do {
                let response = try await NetworkManager.executeFetch(target: UserRouter.refresh(refreshToken), responseType: RefreshResponse.self, errorType: UserErrorResponse.self)
                print(1)
                SecureTokenManager.shared.encryptAndStoreToken(token: response.accessToken, forKey: SecureKey.ACCESS_TOKEN_KEY) { result in
                    print(2)
                    switch result {
                    case .success:
                        print(3)
                        SecureTokenManager.shared.encryptAndStoreToken(token: response.refreshToken, forKey: SecureKey.REFRESH_TOKEN_KEY) { result in
                            switch result {
                            case .success:
                                print(4)
                                completion(.success(()))
                            case .failure(let failure):
                                print(5)
                                completion(.failure(failure))
                            }
                        }
                    case .failure(let failure):
                        print(6)
                        completion(.failure(failure))
                    }
                }
            } catch {
                print(7)
                print("refresh api fail")
                completion(.failure(KeychainError.authFailed))  // refresh 토큰 문제 발생
            }
        }
    }
}

