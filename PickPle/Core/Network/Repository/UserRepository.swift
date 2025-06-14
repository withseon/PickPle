//
//  UserRepository.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Combine

protocol UserRepository {
    func validateEmail(_ email: String) -> AnyPublisher<Result<Void, NetworkError>, Never>
    func signup(_ param: SignUpParam) -> AnyPublisher<Result<JoinResponse, NetworkError>, Never>
    func loginEmail(_ param: SignInParam) -> AnyPublisher<Result<EmailLoginResponse, NetworkError>, Never>
    func profile() -> AnyPublisher<Result<MyProfileResponse, NetworkError>, Never>
    func profile() async throws -> MyProfileResponse
}

final class DefaultUserRepository: UserRepository {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func validateEmail(_ email: String) -> AnyPublisher<Result<Void, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await networkManager.request(
                        target: UserRouter.validateEmail(ValidationEmailRequest(email: email)),
                        responseType: ValidationEmailResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(())))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func signup(_ param: SignUpParam) -> AnyPublisher<Result<JoinResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let dto = JoinRequest(
                        email: param.email,
                        password: param.password,
                        nick: param.nickname,
                        phoneNum: param.phoneNum,
                        deviceToken: DeviceToken.value
                    )
                    let response = try await networkManager.request(
                        target: UserRouter.joinEmail(dto),
                        responseType: JoinResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(response)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loginEmail(_ param: SignInParam) -> AnyPublisher<Result<EmailLoginResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let dto = EmailLoginRequest(
                        email: param.email,
                        password: param.password,
                        deviceToken: DeviceToken.value
                    )
                    let response = try await networkManager.request(
                        target: UserRouter.emailLogin(dto),
                        responseType: EmailLoginResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    
                    SecureTokenManager.shared.encryptAndStoreToken(token: response.accessToken, forKey: SecureKey.ACCESS_TOKEN) { result in
                        switch result {
                        case .success:
                            SecureTokenManager.shared.encryptAndStoreToken(token: response.refreshToken, forKey: SecureKey.REFRESH_TOKEN) { result in
                                switch result {
                                case .success:
                                    promise(.success(.success(response)))
                                case .failure(let failure):
                                    promise(.success(.failure(.unknown(failure))))
                                }
                            }
                        case .failure(let failure):
                            promise(.success(.failure(.unknown(failure))))
                        }
                    }
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func profile() -> AnyPublisher<Result<MyProfileResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: UserRouter.myProfile,
                        responseType: MyProfileResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(response)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func profile() async throws -> MyProfileResponse {
        return try await networkManager.request(
            target: UserRouter.myProfile,
            responseType: MyProfileResponse.self,
            errorType: UserErrorResponse.self
        )
    }
}
