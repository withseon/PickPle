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

    // MARK: - 테스트 시나리오 프로퍼티
    /// Result 값을 미리 설정

    /// 이메일 로그인 API 응답 결과
    var loginEmailResult: Result<LoginResponse, NetworkError>?

    /// 이메일 중복 검증 API 응답 결과
    var validateEmailResult: Result<Void, NetworkError>?

    /// 회원가입 API 응답 결과
    var signupResult: Result<JoinResponse, NetworkError>?

    /// 로그아웃 API 응답 결과
    var logoutResult: Result<Void, NetworkError>?

    /// 프로필 조회 API 응답 결과
    var profileResult: Result<MyProfileResponse, NetworkError>?

    /// 프로필 수정 API 응답 결과
    var updateProfileResult: Result<MyProfileResponse, NetworkError>?

    /// 프로필 이미지 업로드 API 응답 결과
    var uploadProfileImageResult: Result<profileImageResponse, NetworkError>?

    // MARK: - 호출 검증 프로퍼티
    /// 각 메서드가 몇 번 호출되었는지 추적 -> 1번 호출되었는지 확인

    /// loginEmail 메서드 호출 횟수
    var loginEmailCallCount = 0

    /// validateEmail 메서드 호출 횟수
    var validateEmailCallCount = 0

    /// signup 메서드 호출 횟수
    var signupCallCount = 0

    /// logout 메서드 호출 횟수
    var logoutCallCount = 0

    /// profile 메서드 호출 횟수
    var profileCallCount = 0

    /// updateProfile 메서드 호출 횟수
    var updateProfileCallCount = 0

    /// uploadProfileImage 메서드 호출 횟수
    var uploadProfileImageCallCount = 0

    // MARK: - 파라미터 검증 프로퍼티
    /// 각 메서드에 전달된 파라미터 값을 저장 -> 올바른 값 전달 검증

    /// 마지막으로 loginEmail에 전달된 파라미터 (이메일, 비밀번호 포함)
    var lastLoginParam: SignInParam?

    /// 마지막으로 validateEmail에 전달된 이메일 주소
    var lastValidateEmail: String?

    /// 마지막으로 signup에 전달된 파라미터 (회원가입 정보)
    var lastSignupParam: SignUpParam?

    /// 마지막으로 updateProfile에 전달된 파라미터 (프로필 수정 정보)
    var lastUpdateProfileParam: UpdateProfileParam?

    // MARK: - UserRepository Protocol 구현

    /// 이메일 로그인 API 호출을 시뮬레이션
    /// - Parameter param: 로그인 파라미터 (이메일, 비밀번호)
    /// - Returns: 로그인 결과를 담은 Publisher (실제 API 호출 없이 미리 설정된 결과 반환)
    /// - Note: loginEmailResult가 nil이면 기본 에러 반환
    func loginEmail(_ param: SignInParam) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never> {
        // 1. 호출 횟수 증가
        loginEmailCallCount += 1

        // 2. 전달받은 파라미터 저장 (테스트에서 올바른 값이 전달되었는지 검증용)
        lastLoginParam = param

        // 3. Future를 사용하여 비동기 Publisher 생성
        return Future { [weak self] promise in
            guard let self, let result = loginEmailResult else {
                // loginEmailResult가 설정되지 않은 경우 기본 에러 반환
                promise(.success(.failure(.unknown(NSError(domain: "MockUserRepository", code: -1)))))
                return
            }
            // 미리 설정된 결과 반환
            promise(.success(result))
        }
        .eraseToAnyPublisher()
    }

    /// 이메일 중복 검증 API 호출을 시뮬레이션
    func validateEmail(_ email: String) -> AnyPublisher<Result<Void, NetworkError>, Never> {
        validateEmailCallCount += 1
        lastValidateEmail = email

        return Future { [weak self] promise in
            guard let self, let result = validateEmailResult else {
                // 설정된 결과가 없으면 기본적으로 성공 반환
                promise(.success(.success(())))
                return
            }
            promise(.success(result))
        }
        .eraseToAnyPublisher()
    }

    /// 회원가입 API 호출을 시뮬레이션
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

    /// 카카오 로그인 - 테스트에서 사용하지 않으므로 기본 에러 반환
    func loginKakako(_ token: String) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never> {
        return Just(.failure(.unknown(NSError(domain: "MockUserRepository", code: -1)))).eraseToAnyPublisher()
    }

    /// 애플 로그인 - 테스트에서 사용하지 않으므로 기본 에러 반환
    func loginApple(_ token: String) -> AnyPublisher<Result<LoginResponse, NetworkError>, Never> {
        return Just(.failure(.unknown(NSError(domain: "MockUserRepository", code: -1)))).eraseToAnyPublisher()
    }

    /// 로그아웃 API 호출을 시뮬레이션
    func logout() -> AnyPublisher<Result<Void, NetworkError>, Never> {
        logoutCallCount += 1

        return Future { [weak self] promise in
            guard let self, let result = logoutResult else {
                // 설정된 결과가 없으면 기본적으로 성공 반환
                promise(.success(.success(())))
                return
            }
            promise(.success(result))
        }
        .eraseToAnyPublisher()
    }

    /// 디바이스 토큰 등록 - 테스트에서 사용하지 않으므로 빈 구현
    func deviceToken() async throws -> Void { }

    /// 프로필 조회 API (Publisher 버전)
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

    /// 프로필 조회 API (async/await 버전)
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

    /// 프로필 수정 API 호출을 시뮬레이션
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

    /// 프로필 이미지 업로드 API 호출을 시뮬레이션
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
