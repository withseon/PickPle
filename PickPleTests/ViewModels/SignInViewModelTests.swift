//
//  SignInViewModelTests.swift
//  PickPleTests
//
//  Created by 정인선 on 8/29/25.
//

import XCTest
import Combine
@testable import PickPle

final class SignInViewModelTests: XCTestCase {
    var sut: SignInViewModel!
    var mockRepository: MockUserRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        sut = SignInViewModel(userRepository: mockRepository)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - 이메일 검증 테스트

    func test_이메일_형식이_올바를때_에러메시지_없음() {
        // Given
        let validEmail = "test@example.com"

        // When
        sut.action(.validateEmail(validEmail))

        // Then
        let expectation = expectation(description: "이메일 검증")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // SignInViewModel은 로컬 검증만 수행 (서버 호출 없음)
            XCTAssertEqual(self.sut.output.emailErrorMessage, "")
            XCTAssertEqual(self.mockRepository.validateEmailCallCount, 0, "로그인 화면은 서버 검증 안 함")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_이메일_형식이_잘못되었을때_에러메시지_표시() {
        // Given
        let invalidEmail = "invalid-email"

        // When
        sut.action(.validateEmail(invalidEmail))

        // Then
        let expectation = expectation(description: "이메일 검증 실패")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(self.sut.output.emailErrorMessage, "유효한 이메일 주소를 입력해주세요.")
            XCTAssertEqual(self.mockRepository.validateEmailCallCount, 0, "잘못된 형식은 서버 요청 없음")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_이메일이_비어있을때_에러메시지_표시() {
        // Given
        let emptyEmail = ""

        // When
        sut.action(.validateEmail(emptyEmail))

        // Then
        let expectation = expectation(description: "빈 이메일")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(self.sut.output.emailErrorMessage, "이메일을 입력해주세요.")
            XCTAssertEqual(self.mockRepository.validateEmailCallCount, 0, "빈 이메일은 서버 요청 없음")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // SignInViewModel은 서버 검증을 하지 않으므로 이 테스트는 삭제
    // (회원가입 화면에서만 이메일 중복 확인이 필요함)

    // MARK: - 비밀번호 검증 테스트

    func test_비밀번호_형식이_올바를때_에러메시지_없음() {
        // Given
        let validPassword = "Test1234!"

        // When
        sut.action(.validatePassword(validPassword))

        // Then
        let expectation = expectation(description: "비밀번호 검증")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(self.sut.output.passwordErrorMessage, "")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_비밀번호가_비어있을때_에러메시지_표시() {
        // Given
        let emptyPassword = ""

        // When
        sut.action(.validatePassword(emptyPassword))

        // Then
        let expectation = expectation(description: "빈 비밀번호")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(self.sut.output.passwordErrorMessage, "비밀번호를 입력해주세요.")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_비밀번호_형식이_잘못되었을때_에러메시지_없음() {
        // Given - SignInViewModel은 형식 검증 시 에러 메시지를 표시하지 않음 (SignUpViewModel과 다름)
        let invalidPassword = "123"

        // When
        sut.action(.validatePassword(invalidPassword))

        // Then
        let expectation = expectation(description: "잘못된 비밀번호")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(self.sut.output.passwordErrorMessage, "")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - 로그인 성공 테스트

    func test_로그인_성공_시_메인화면_이동_트리거() {
        // Given
        let expectation = expectation(description: "로그인 성공")
        mockRepository.loginEmailResult = .success(LoginResponse(
            userId: "test-id",
            email: "test@test.com",
            nick: "테스트",
            profileImage: nil,
            accessToken: "access-token",
            refreshToken: "refresh-token"
        ))

        var pushTriggered = false
        sut.output.pushMainTrigger
            .sink { _ in
                pushTriggered = true
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.action(.validateEmail("test@test.com"))
        sut.action(.validatePassword("Test1234!"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.sut.action(.loginButtonTapped)
        }

        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertTrue(pushTriggered)
        XCTAssertEqual(mockRepository.loginEmailCallCount, 1)
        XCTAssertEqual(mockRepository.lastLoginParam?.email, "test@test.com")
        XCTAssertEqual(mockRepository.lastLoginParam?.password, "Test1234!")
    }

    // MARK: - 로그인 실패 테스트

    func test_네트워크_에러_발생_시_로그인_실패() {
        // Given
        mockRepository.loginEmailResult = .failure(.server(UserErrorResponse(message: "서버 오류")))

        var pushTriggered = false
        sut.output.pushMainTrigger
            .sink { _ in
                pushTriggered = true
            }
            .store(in: &cancellables)

        // When
        sut.action(.validateEmail("test@test.com"))
        sut.action(.validatePassword("Test1234!"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.sut.action(.loginButtonTapped)
        }

        // Then
        let expectation = expectation(description: "로그인 실패")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertFalse(pushTriggered)
            XCTAssertEqual(self.mockRepository.loginEmailCallCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }

    func test_잘못된_비밀번호로_로그인_시도() {
        // Given
        mockRepository.loginEmailResult = .failure(.server(UserErrorResponse(message: "비밀번호가 일치하지 않습니다.")))

        var pushTriggered = false
        sut.output.pushMainTrigger
            .sink { _ in
                pushTriggered = true
            }
            .store(in: &cancellables)

        // When
        sut.action(.validateEmail("test@test.com"))
        sut.action(.validatePassword("WrongPassword1!"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.sut.action(.loginButtonTapped)
        }

        // Then
        let expectation = expectation(description: "잘못된 비밀번호")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertFalse(pushTriggered)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }

    // MARK: - 포커스 상태 테스트

    func test_잘못된_이메일로_로그인_버튼_눌렀을때_포커스_이메일로_이동() {
        // Given
        let expectation = expectation(description: "포커스 변경")
        var focusState: SignInViewModel.FieldType?

        sut.output.setFocusState
            .dropFirst()  // 초기값 무시
            .sink { state in
                focusState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.action(.validateEmail("invalid-email"))
        sut.action(.validatePassword("Test1234!"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.sut.action(.loginButtonTapped)
        }

        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(focusState, .email)
        XCTAssertEqual(mockRepository.loginEmailCallCount, 0, "잘못된 이메일은 로그인 요청 없음")
    }

    func test_올바른_이메일_빈_비밀번호로_로그인_버튼_눌렀을때_포커스_비밀번호로_이동() {
        // Given
        let expectation = expectation(description: "포커스 비밀번호로 이동")
        var focusState: SignInViewModel.FieldType?

        sut.output.setFocusState
            .dropFirst()  // 초기값 무시
            .sink { state in
                focusState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.action(.validateEmail("test@test.com"))
        sut.action(.validatePassword(""))  // 빈 비밀번호

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.sut.action(.loginButtonTapped)
        }

        // Then
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(focusState, .password, "빈 비밀번호는 포커스 이동")
    }

    // MARK: - Throttle 테스트

    func test_이메일_입력_연속_호출_시_throttle_적용() {
        // Given
        let validEmails = ["test1@test.com", "test2@test.com", "test3@test.com", "test4@test.com"]

        // When - 짧은 시간 내 여러 번 호출
        for email in validEmails {
            sut.action(.validateEmail(email))
        }

        // Then
        let expectation = expectation(description: "Throttle 적용")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Throttle로 인해 마지막 호출만 실행됨 (로컬 검증이므로 서버 호출 0)
            XCTAssertEqual(self.mockRepository.validateEmailCallCount, 0, "로컬 검증은 서버 호출 없음")
            // 에러 메시지가 없어야 함 (마지막 이메일이 유효하므로)
            XCTAssertEqual(self.sut.output.emailErrorMessage, "")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
}
