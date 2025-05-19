//
//  SignUpPasswordViewModel.swift
//  PickPle
//
//  Created by 정인선 on 5/12/25.
//

import Foundation
import Combine

final class SignUpPasswordViewModel: ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()

    init() {
        transform()
    }

    deinit {
        print("SignUpPasswordViewModel deinit")
    }
}

// MARK: - Input/Output
extension SignUpPasswordViewModel {
    struct Input {
        var password = ""
        var passwordConfirmation = ""
        let validatePasswordTrigger = PassthroughSubject<Void, Never>()
        let confirmPasswordTrigger = PassthroughSubject<Void, Never>()
        
    }

    struct Output {
        var passwordErrorMessage = ""
        var passwordConfirmErrorMessage = ""
        var nextButtonDisable = true
    }

    func transform() {
        input.validatePasswordTrigger
            .merge(with: input.confirmPasswordTrigger)
            .sink { [weak self] _ in
                guard let self else { return }
                let validPassword = validatePassword()
                let confirmPassword = confirmPassword()
                output.nextButtonDisable = !validPassword || !confirmPassword
            }
            .store(in: &cancellables)
    }
    
    private func validatePassword() -> Bool {
        if input.password.isEmpty {
            output.passwordErrorMessage = ""
            return false
        } else {
            let detail = input.password.passwordValidationDetails()
            if !detail.isValid {
                if !detail.lengthValid {
                    output.passwordErrorMessage = "비밀번호는 8자 이상이어야 합니다."
                } else if !detail.hasDigits {
                    output.passwordErrorMessage = "비밀번호는 숫자를 포함해야 합니다."
                } else if !detail.hasLetters {
                    output.passwordErrorMessage = "비밀번호는 영문자를 포함해야 합니다."
                } else if !detail.hasSpecial {
                    output.passwordErrorMessage = "비밀번호는 특수문자(@$!%*#?&)를 포함해야 합니다."
                } else { }
                return false
            } else {
                output.passwordErrorMessage = ""
                return true
            }
        }
    }
    
    private func confirmPassword() -> Bool {
        if input.password.isEmpty || input.passwordConfirmation.isEmpty {
            output.passwordConfirmErrorMessage = ""
            return false
        } else if input.password == input.passwordConfirmation {
            output.passwordConfirmErrorMessage = ""
            return true
        } else {
            output.passwordConfirmErrorMessage = "비밀번호가 일치하지 않습니다."
            return false
        }
    }
}

// MARK: - Action
extension SignUpPasswordViewModel {
    enum Action {
        case validatePassword
        case confirmPassword
    }

    func action(_ action: Action) {
        switch action {
        case .validatePassword:
            input.validatePasswordTrigger
                .send(())
        case .confirmPassword:
            input.confirmPasswordTrigger
                .send(())
        }
    }
}

