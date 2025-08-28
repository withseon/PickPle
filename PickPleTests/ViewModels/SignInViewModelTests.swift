//
//  SignInViewModelTests.swift
//  PickPleTests
//
//  Created by 정인선 on 8/29/25.
//

import XCTest
import Combine
@testable import PickPle

/// SignInViewModel의 단위 테스트
/// - 이메일/비밀번호 검증, 로그인 성공/실패, 포커스 상태, Throttle 등을 테스트
final class SignInViewModelTests: XCTestCase {

    // MARK: - Test Properties

    /// 테스트 대상인 SignInViewModel
    var sut: SignInViewModel!

    /// Mock Repository
    var mockRepository: MockUserRepository!

    /// Combine 구독 관리
    var cancellables: Set<AnyCancellable>!

    // MARK: - Test Lifecycle

    /// 각 테스트 실행 전 호출 - 초기 설정
    override func setUp() {
        super.setUp()

        // 1. Mock Repository 생성
        mockRepository = MockUserRepository()

        // 2. SignInViewModel에 Mock Repository 주입
        sut = SignInViewModel(userRepository: mockRepository)

        // 3. Combine 구독 관리용 Set 초기화
        cancellables = []
    }

    /// 각 테스트 실행 후 호출 - 정리 작업
    override func tearDown() {
        // 메모리 해제 및 다음 테스트를 위한 초기화
        sut = nil
        mockRepository = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - 이메일 검증 테스트

    /// 올바른 이메일 형식 입력 시 에러 메시지가 없는지 검증
    /// - 테스트 시나리오: "test@example.com" 입력 → 에러 메시지 없음
    /// - 검증 포인트:
    ///   1. 에러 메시지가 빈 문자열인지
    ///   2. 서버 API 호출이 발생하지 않았는지 (로컬 검증만 수행)
    func test_이메일_형식이_올바를때_에러메시지_없음() {
        // Given (준비): 테스트에 필요한 데이터 준비
        let validEmail = "test@example.com"

        // When (실행): 테스트하고자 하는 동작 실행
        sut.action(.validateEmail(validEmail))

        // Then (검증): 결과가 기대한 대로인지 확인
        let expectation = expectation(description: "이메일 검증")

        // Throttle로 인한 0.5초 대기 후 검증
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 1. 에러 메시지가 없어야 함 (올바른 형식이므로)
            XCTAssertEqual(self.sut.output.emailErrorMessage, "")

            // 2. SignInViewModel은 로컬 검증만 수행 (서버 호출 없음)
            //    - SignUpViewModel과 다르게 이메일 중복 확인 API를 호출하지 않음
            XCTAssertEqual(self.mockRepository.validateEmailCallCount, 0, "로그인 화면은 서버 검증 안 함")

            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    /// 잘못된 이메일 형식 입력 시 에러 메시지가 표시되는지 검증
    /// - 테스트 시나리오: "invalid-email" (@ 없음) 입력 → 에러 메시지 표시
    func test_이메일_형식이_잘못되었을때_에러메시지_표시() {
        // Given
        let invalidEmail = "invalid-email"

        // When
        sut.action(.validateEmail(invalidEmail))

        // Then
        let expectation = expectation(description: "이메일 검증 실패")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 잘못된 형식이므로 에러 메시지 표시
            XCTAssertEqual(self.sut.output.emailErrorMessage, "유효한 이메일 주소를 입력해주세요.")

            // 형식이 잘못되어 서버 요청 발생하지 않음
            XCTAssertEqual(self.mockRepository.validateEmailCallCount, 0, "잘못된 형식은 서버 요청 없음")

            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    /// 빈 이메일 입력 시 에러 메시지가 표시되는지 검증
    /// - 테스트 시나리오: "" (빈 문자열) 입력 → 에러 메시지 표시
    func test_이메일이_비어있을때_에러메시지_표시() {
        // Given
        let emptyEmail = ""

        // When
        sut.action(.validateEmail(emptyEmail))

        // Then
        let expectation = expectation(description: "빈 이메일")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 빈 이메일은 별도의 에러 메시지 표시
            XCTAssertEqual(self.sut.output.emailErrorMessage, "이메일을 입력해주세요.")

            // 빈 값이므로 서버 요청 없음
            XCTAssertEqual(self.mockRepository.validateEmailCallCount, 0, "빈 이메일은 서버 요청 없음")

            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // ⚠️ 참고: SignInViewModel은 서버 검증을 하지 않음
    // - 이메일 중복 확인은 회원가입(SignUpViewModel)에서만 필요
    // - 로그인은 형식만 검증하고 실제 존재 여부는 로그인 API에서 확인

    // MARK: - 비밀번호 검증 테스트

    /// 올바른 비밀번호 형식 입력 시 에러 메시지가 없는지 검증
    /// - 테스트 시나리오: "Test1234!" (대문자+소문자+숫자+특수문자) → 에러 메시지 없음
    func test_비밀번호_형식이_올바를때_에러메시지_없음() {
        // Given
        let validPassword = "Test1234!"

        // When
        sut.action(.validatePassword(validPassword))

        // Then
        let expectation = expectation(description: "비밀번호 검증")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 올바른 형식이므로 에러 메시지 없음
            XCTAssertEqual(self.sut.output.passwordErrorMessage, "")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    /// 빈 비밀번호 입력 시 에러 메시지가 표시되는지 검증
    /// - 테스트 시나리오: "" (빈 문자열) → 에러 메시지 표시
    func test_비밀번호가_비어있을때_에러메시지_표시() {
        // Given
        let emptyPassword = ""

        // When
        sut.action(.validatePassword(emptyPassword))

        // Then
        let expectation = expectation(description: "빈 비밀번호")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 빈 비밀번호는 에러 메시지 표시
            XCTAssertEqual(self.sut.output.passwordErrorMessage, "비밀번호를 입력해주세요.")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    /// 잘못된 비밀번호 형식 입력 시에도 에러 메시지가 없는지 검증
    /// - 테스트 시나리오: "123" (형식 미충족) → 에러 메시지 없음
    /// - ⚠️ SignInViewModel은 로그인 시 비밀번호 형식 검증을 하지 않음
    ///   (회원가입과 달리 로그인은 서버에서 검증)
    func test_비밀번호_형식이_잘못되었을때_에러메시지_없음() {
        // Given - SignInViewModel은 형식 검증 시 에러 메시지를 표시하지 않음
        let invalidPassword = "123"

        // When
        sut.action(.validatePassword(invalidPassword))

        // Then
        let expectation = expectation(description: "잘못된 비밀번호")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 로그인 화면은 비밀번호 형식 검증 없음 (빈 값만 체크)
            XCTAssertEqual(self.sut.output.passwordErrorMessage, "")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - 로그인 성공 테스트

    /// 로그인 성공 시 메인 화면으로 이동하는 트리거가 발생하는지 검증
    /// - 테스트 시나리오:
    ///   1. Mock Repository에 성공 응답 설정
    ///   2. 이메일/비밀번호 입력
    ///   3. 로그인 버튼 탭
    ///   4. pushMainTrigger 이벤트 발생 확인
    /// - 검증 포인트:
    ///   1. pushMainTrigger가 발생했는가
    ///   2. loginEmail API가 정확히 1번 호출되었는가
    ///   3. 올바른 파라미터(이메일, 비밀번호)가 전달되었는가
    func test_로그인_성공_시_메인화면_이동_트리거() {
        // Given - Mock에 성공 응답 설정
        let expectation = expectation(description: "로그인 성공")

        // 1. Mock Repository에 성공 시 반환할 응답 데이터 설정
        mockRepository.loginEmailResult = .success(LoginResponse(
            userId: "test-id",
            email: "test@test.com",
            nick: "테스트",
            profileImage: nil,
            accessToken: "access-token",
            refreshToken: "refresh-token"
        ))

        // 2. pushMainTrigger 이벤트 감지 (Combine 구독)
        var pushTriggered = false
        sut.output.pushMainTrigger
            .sink { _ in
                pushTriggered = true  // 트리거 발생 시 플래그 변경
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When - 이메일/비밀번호 입력 후 로그인 버튼 탭
        sut.action(.validateEmail("test@test.com"))
        sut.action(.validatePassword("Test1234!"))

        // Throttle 0.5초 대기 후 로그인 버튼 탭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.sut.action(.loginButtonTapped)
        }

        // Then - 결과 검증
        waitForExpectations(timeout: 2.0)

        // 1. 메인 화면 이동 트리거 발생 확인
        XCTAssertTrue(pushTriggered)

        // 2. loginEmail API가 정확히 1번 호출되었는지 확인
        XCTAssertEqual(mockRepository.loginEmailCallCount, 1)

        // 3. 올바른 파라미터가 전달되었는지 확인
        XCTAssertEqual(mockRepository.lastLoginParam?.email, "test@test.com")
        XCTAssertEqual(mockRepository.lastLoginParam?.password, "Test1234!")
    }

    // MARK: - 로그인 실패 테스트

    /// 네트워크 에러 발생 시 로그인 실패하고 화면 이동이 일어나지 않는지 검증
    /// - 테스트 시나리오:
    ///   1. Mock에 서버 에러 응답 설정
    ///   2. 로그인 시도
    ///   3. pushMainTrigger 이벤트가 발생하지 않는지 확인
    func test_네트워크_에러_발생_시_로그인_실패() {
        // Given - Mock에 실패 응답 설정
        mockRepository.loginEmailResult = .failure(.server(UserErrorResponse(message: "서버 오류")))

        var pushTriggered = false
        sut.output.pushMainTrigger
            .sink { _ in
                pushTriggered = true  // 이 코드가 실행되면 안 됨
            }
            .store(in: &cancellables)

        // When - 로그인 시도
        sut.action(.validateEmail("test@test.com"))
        sut.action(.validatePassword("Test1234!"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.sut.action(.loginButtonTapped)
        }

        // Then - 실패 검증
        let expectation = expectation(description: "로그인 실패")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 1. 화면 이동 트리거가 발생하지 않아야 함
            XCTAssertFalse(pushTriggered)

            // 2. API 호출은 1번 발생했어야 함 (실패했지만 호출은 됨)
            XCTAssertEqual(self.mockRepository.loginEmailCallCount, 1)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }

    /// 잘못된 비밀번호로 로그인 시도 시 실패하는지 검증
    /// - 테스트 시나리오: 서버에서 "비밀번호 불일치" 에러 응답
    func test_잘못된_비밀번호로_로그인_시도() {
        // Given - 비밀번호 불일치 에러 설정
        mockRepository.loginEmailResult = .failure(.server(UserErrorResponse(message: "비밀번호가 일치하지 않습니다.")))

        var pushTriggered = false
        sut.output.pushMainTrigger
            .sink { _ in
                pushTriggered = true
            }
            .store(in: &cancellables)

        // When - 잘못된 비밀번호로 로그인 시도
        sut.action(.validateEmail("test@test.com"))
        sut.action(.validatePassword("WrongPassword1!"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.sut.action(.loginButtonTapped)
        }

        // Then - 화면 이동이 일어나지 않아야 함
        let expectation = expectation(description: "잘못된 비밀번호")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertFalse(pushTriggered)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }

    // MARK: - 포커스 상태 테스트

    /// 잘못된 이메일로 로그인 시도 시 포커스가 이메일 필드로 이동하는지 검증
    /// - 테스트 시나리오:
    ///   1. 잘못된 형식의 이메일 입력
    ///   2. 올바른 비밀번호 입력
    ///   3. 로그인 버튼 탭
    ///   4. 포커스가 이메일 필드로 이동하는지 확인
    /// - UX 목적: 사용자가 어떤 필드를 수정해야 하는지 명확하게 안내
    func test_잘못된_이메일로_로그인_버튼_눌렀을때_포커스_이메일로_이동() {
        // Given
        let expectation = expectation(description: "포커스 변경")
        var focusState: SignInViewModel.FieldType?

        // setFocusState 이벤트 감지
        sut.output.setFocusState
            .dropFirst()  // 초기값 무시 (nil 상태)
            .sink { state in
                focusState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When - 잘못된 이메일 + 올바른 비밀번호
        sut.action(.validateEmail("invalid-email"))
        sut.action(.validatePassword("Test1234!"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.sut.action(.loginButtonTapped)
        }

        // Then
        waitForExpectations(timeout: 2.0)

        // 1. 포커스가 이메일 필드로 이동해야 함
        XCTAssertEqual(focusState, .email)

        // 2. 잘못된 이메일이므로 로그인 API 호출되지 않음
        XCTAssertEqual(mockRepository.loginEmailCallCount, 0, "잘못된 이메일은 로그인 요청 없음")
    }

    /// 올바른 이메일, 빈 비밀번호로 로그인 시도 시 포커스가 비밀번호 필드로 이동하는지 검증
    /// - 테스트 시나리오:
    ///   1. 올바른 이메일 입력
    ///   2. 빈 비밀번호
    ///   3. 로그인 버튼 탭
    ///   4. 포커스가 비밀번호 필드로 이동하는지 확인
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

        // When - 올바른 이메일 + 빈 비밀번호
        sut.action(.validateEmail("test@test.com"))
        sut.action(.validatePassword(""))  // 빈 비밀번호

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.sut.action(.loginButtonTapped)
        }

        // Then
        waitForExpectations(timeout: 2.0)

        // 포커스가 비밀번호 필드로 이동해야 함
        XCTAssertEqual(focusState, .password, "빈 비밀번호는 포커스 이동")
    }

    // MARK: - Throttle 테스트

    /// 이메일 입력 연속 호출 시 Throttle이 적용되는지 검증
    /// - 테스트 시나리오:
    ///   1. 짧은 시간 내에 여러 이메일 입력 (4번)
    ///   2. Throttle(0.5초)로 인해 마지막 값만 검증됨
    /// - Throttle 목적:
    ///   - 사용자가 타이핑하는 동안 불필요한 검증 방지
    ///   - 성능 최적화 (과도한 검증 호출 방지)
    ///   - 마지막 입력값만 유효성 검증
    func test_이메일_입력_연속_호출_시_throttle_적용() {
        // Given - 4개의 유효한 이메일
        let validEmails = ["test1@test.com", "test2@test.com", "test3@test.com", "test4@test.com"]

        // When - 짧은 시간 내 여러 번 호출
        for email in validEmails {
            sut.action(.validateEmail(email))
        }

        // Then
        let expectation = expectation(description: "Throttle 적용")

        // Throttle 0.5초 + 여유시간 후 검증
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 1. SignInViewModel은 로컬 검증만 수행하므로 서버 호출 없음
            XCTAssertEqual(self.mockRepository.validateEmailCallCount, 0, "로컬 검증은 서버 호출 없음")

            // 2. Throttle로 인해 마지막 이메일(test4@test.com)만 검증됨
            //    마지막 이메일이 유효하므로 에러 메시지 없음
            XCTAssertEqual(self.sut.output.emailErrorMessage, "")

            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
}
