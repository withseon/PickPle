//
//  UserRepository.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation
import Combine

protocol UserRepository {
    func validateEmail(_ email: String) -> AnyPublisher<Result<Void, NetworkError>, Never>
    func signup(_ param: SignUpParam) -> AnyPublisher<Result<JoinResponse, NetworkError>, Never>
    func loginEmail(_ param: SignInParam) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never>
    func loginKakako(_ token: String) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never>
    func loginApple(_ token: String) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never>
    func logout() -> AnyPublisher<Result<Void, NetworkError>, Never>
    func deviceToken() async throws -> Void
    func profile() -> AnyPublisher<Result<MyProfileResponse, NetworkError>, Never>
    func profile() async throws -> MyProfileResponse
    func updateProfile(_ param: UpdateProfileParam) -> AnyPublisher<Result<MyProfileResponse, NetworkError>, Never>
    func uploadProfileImage(_ file: MultipartFile) -> AnyPublisher<Result<profileImageResponse, NetworkError>, Never>
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
                    // 회원가입 성공 시 userId 저장 (JoinResponse도 TokenResponse 구현)
                    UserDefaultsManager.userId = response.userId
                    await storeTokens(response: response, promise: promise)
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
    
    func loginEmail(_ param: SignInParam) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never> {
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
                        responseType: LoginResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    // 로그인 성공 시 userId 저장
                    UserDefaultsManager.userId = response.userId
                    await storeTokens(response: response, promise: promise)
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
    
    func loginKakako(_ token: String) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let dto = KakaoLoginRequest(
                        oauthToken: token,
                        deviceToken: DeviceToken.value
                    )
                    let response = try await networkManager.request(
                        target: UserRouter.kakaoLogin(dto),
                        responseType: LoginResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    // 로그인 성공 시 userId 저장
                    UserDefaultsManager.userId = response.userId
                    await storeTokens(response: response, promise: promise)
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
    
    func loginApple(_ token: String) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
//                do {
//                    await storeTokens(response: <#T##T#>, promise: <#T##(Result<Result<T, NetworkError>, Never>) -> Void#>)
//                } catch {
//                    if case let NetworkError.server(serverError) = error {
//                        promise(.success(.failure(.server(serverError))))
//                    } else {
//                        promise(.success(.failure(.unknown(error))))
//                    }
//                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Result<Void, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await networkManager.requestVoid(
                        target: UserRouter.logout,
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
    
    func deviceToken() async throws -> Void {
        return try await networkManager.requestVoid(
            target: UserRouter.deviceToken(
                DeviceTokenRequest(
                    deviceToken: DeviceToken.value ?? ""
                )
            ),
            errorType: UserErrorResponse.self)
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
        let response = try await networkManager.request(
            target: UserRouter.myProfile,
            responseType: MyProfileResponse.self,
            errorType: UserErrorResponse.self
        )
        
        // userId는 로그인 시에 이미 설정되므로 여기서는 userProfile만 업데이트
        if UserDefaultsManager.userProfile == nil {
            UserDefaultsManager.userProfile = UserProfile(
                userId: response.userId,
                email: response.email,
                nickname: response.nick,
                profileImage: response.profileImage,
                phoneNum: response.phoneNum
            )
        }
        return response
    }
    
    func updateProfile(_ param: UpdateProfileParam) -> AnyPublisher<Result<MyProfileResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let dto = UpdateProfileRequest(
                        nick: param.nick,
                        phoneNum: param.phoneNum,
                        profileImage: param.profileImage
                    )
                    let response = try await networkManager.request(
                        target: UserRouter.updateProfile(dto),
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
    
    func uploadProfileImage(_ file: MultipartFile) -> AnyPublisher<Result<profileImageResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let profileImage = try await networkManager.uploadMultipart(
                        target: UserRouter.uploadProfileImage,
                        fileData: [file],
                        responseType: profileImageResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(profileImage)))
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
}

extension DefaultUserRepository {
    private func storeTokens<T: TokenResponse>(
        response: T,
        promise: @escaping (Result<Result<T, NetworkError>, Never>) -> Void
    ) async {
        do {
            // 병렬로 저장
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await TokenManager.shared.save(response.accessToken, forKey: SecureKey.ACCESS_TOKEN)
                }
                group.addTask {
                    try await TokenManager.shared.save(response.refreshToken, forKey: SecureKey.REFRESH_TOKEN)
                }
                try await group.waitForAll()
            }
            promise(.success(.success(response)))
        } catch {
            promise(.success(.failure(.unknown(error))))
        }
    }
}
