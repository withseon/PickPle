//
//  MockUserRepository.swift
//  PickPleTests
//
//  Created by 정인선 on 8/29/25.
//

import Foundation
import Combine
@testable import PickPle

final class MockUserRepository: UserRepository {
    // 테스트 시나리오 제어
    var loginEmailResult: Result<LoginResponse, NetworkError>?
    var validateEmailResult: Result<Void, NetworkError>?
    var signupResult: Result<JoinResponse, NetworkError>?
    var logoutResult: Result<Void, NetworkError>?
    var profileResult: Result<MyProfileResponse, NetworkError>?
    var updateProfileResult: Result<MyProfileResponse, NetworkError>?
    var uploadProfileImageResult: Result<profileImageResponse, NetworkError>?

    // 호출 여부 검증용
    var loginEmailCallCount = 0
    var validateEmailCallCount = 0
    var signupCallCount = 0
    var logoutCallCount = 0
    var profileCallCount = 0
    var updateProfileCallCount = 0
    var uploadProfileImageCallCount = 0

    // 파라미터 검증용
    var lastLoginParam: SignInParam?
    var lastValidateEmail: String?
    var lastSignupParam: SignUpParam?
    var lastUpdateProfileParam: UpdateProfileParam?

    func loginEmail(_ param: SignInParam) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never> {
        loginEmailCallCount += 1
        lastLoginParam = param

        return Future { [weak self] promise in
            guard let self, let result = loginEmailResult else {
                promise(.success(.failure(.unknown(NSError(domain: "MockUserRepository", code: -1)))))
                return
            }
            promise(.success(result))
        }
        .eraseToAnyPublisher()
    }

    func validateEmail(_ email: String) -> AnyPublisher<Result<Void, NetworkError>, Never> {
        validateEmailCallCount += 1
        lastValidateEmail = email

        return Future { [weak self] promise in
            guard let self, let result = validateEmailResult else {
                promise(.success(.success(())))
                return
            }
            promise(.success(result))
        }
        .eraseToAnyPublisher()
    }

    func signup(_ param: SignUpParam) -> AnyPublisher<Result<JoinResponse, NetworkError>, Never> {
        signupCallCount += 1
        lastSignupParam = param

        return Future { [weak self] promise in
            guard let self, let result = signupResult else {
                promise(.success(.failure(.unknown(NSError(domain: "MockUserRepository", code: -1)))))
                return
            }
            promise(.success(result))
        }
        .eraseToAnyPublisher()
    }

    func loginKakako(_ token: String) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never> {
        return Just(.failure(.unknown(NSError(domain: "MockUserRepository", code: -1)))).eraseToAnyPublisher()
    }

    func loginApple(_ token: String) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never> {
        return Just(.failure(.unknown(NSError(domain: "MockUserRepository", code: -1)))).eraseToAnyPublisher()
    }

    func logout() -> AnyPublisher<Result<Void, NetworkError>, Never> {
        logoutCallCount += 1

        return Future { [weak self] promise in
            guard let self, let result = logoutResult else {
                promise(.success(.success(())))
                return
            }
            promise(.success(result))
        }
        .eraseToAnyPublisher()
    }

    func deviceToken() async throws -> Void {
        // Mock implementation
    }

    func profile() -> AnyPublisher<Result<MyProfileResponse, NetworkError>, Never> {
        profileCallCount += 1

        return Future { [weak self] promise in
            guard let self, let result = profileResult else {
                promise(.success(.failure(.unknown(NSError(domain: "MockUserRepository", code: -1)))))
                return
            }
            promise(.success(result))
        }
        .eraseToAnyPublisher()
    }

    func profile() async throws -> MyProfileResponse {
        profileCallCount += 1

        guard let result = profileResult else {
            throw NSError(domain: "MockUserRepository", code: -1)
        }

        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func updateProfile(_ param: UpdateProfileParam) -> AnyPublisher<Result<MyProfileResponse, NetworkError>, Never> {
        updateProfileCallCount += 1
        lastUpdateProfileParam = param

        return Future { [weak self] promise in
            guard let self, let result = updateProfileResult else {
                promise(.success(.failure(.unknown(NSError(domain: "MockUserRepository", code: -1)))))
                return
            }
            promise(.success(result))
        }
        .eraseToAnyPublisher()
    }

    func uploadProfileImage(_ file: MultipartFile) -> AnyPublisher<Result<profileImageResponse, NetworkError>, Never> {
        uploadProfileImageCallCount += 1

        return Future { [weak self] promise in
            guard let self, let result = uploadProfileImageResult else {
                promise(.success(.failure(.unknown(NSError(domain: "MockUserRepository", code: -1)))))
                return
            }
            promise(.success(result))
        }
        .eraseToAnyPublisher()
    }
}
