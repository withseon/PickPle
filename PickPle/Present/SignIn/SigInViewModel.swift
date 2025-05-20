//
//  SigInViewModel.swift
//  PickPle
//
//  Created by 정인선 on 5/11/25.
//

import Foundation
import Combine

final class SignInViewModel: ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    enum FieldType {
        case email, password
    }

    init() {
        transform()
    }

    deinit {
        print("SignInViewModel deinit")
    }
}

// MARK: - Input/Output
extension SignInViewModel {
    struct Input {
        var email = ""
        var password = ""
        let validateEmailTrigger = PassthroughSubject<Void, Never>()
        let validatePasswordTrigger = PassthroughSubject<Void, Never>()
        let loginValidateTrigger = PassthroughSubject<Void, Never>()
    }

    struct Output {
        var emailErrorMessage = ""
        var passwordErrorMessage = ""
        let setFocusState = CurrentValueSubject<FieldType?, Never>(nil)
    }

    func transform() {
        input.validateEmailTrigger
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                validateEmail()
            }
            .store(in: &cancellables)
        
        input.validatePasswordTrigger
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                validatePassword()
            }
            .store(in: &cancellables)
        
        input.loginValidateTrigger
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                let validateEmail = validateEmail()
                let validatePassword = validatePassword()
                
                if !validateEmail {
                    output.setFocusState
                        .send(.email)
                } else if !validatePassword {
                    output.setFocusState
                        .send(output.passwordErrorMessage.isEmpty ? nil : .password)
                } else {
                    output.setFocusState
                        .send(nil)
                    // TODO: 로그인 네트워크
                    print("네트워크 처리")
                }
            }
            .store(in: &cancellables)
    }
    
    @discardableResult
    private func validateEmail() -> Bool {
        if input.email.isEmpty {
            output.emailErrorMessage = "이메일을 입력해주세요."
            return false
        } else if !input.email.isValidEmail() {
            output.emailErrorMessage = "유효한 이메일 주소를 입력해주세요."
            return false
        } else {
            output.emailErrorMessage = ""
            return true
        }
    }
    
    @discardableResult
    private func validatePassword() -> Bool {
        if input.password.isEmpty {
            output.passwordErrorMessage = "비밀번호를 입력해주세요."
            return false
        } else if !input.password.isValidPassword() {
            output.passwordErrorMessage = ""
            return false
        } else {
            output.passwordErrorMessage = ""
            return true
        }
    }
}

// MARK: - Action
extension SignInViewModel {
    enum Action {
        case validateEmail
        case validatePassword
        case loginButtonTapped
    }

    func action(_ action: Action) {
        switch action {
        case .validateEmail:
            input.validateEmailTrigger
                .send(())
        case .validatePassword:
            input.validatePasswordTrigger
                .send(())
        case .loginButtonTapped:
            input.loginValidateTrigger
                .send(())
        }
    }
}
