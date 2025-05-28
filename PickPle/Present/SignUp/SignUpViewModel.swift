//
//  SignUpViewModel.swift
//  PickPle
//
//  Created by 정인선 on 5/16/25.
//

import Foundation
import Combine

final class SignUpViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    private var signUpParam = SignUpParam.empty
    private let userRepository: UserRepository
    
    enum State {
        case email, password, info
    }
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        super.init()
        transform()
    }
}

// MARK: - Input/Output
extension SignUpViewModel {
    struct Input {
        let validateEmailTrigger = PassthroughSubject<String, Never>()
        let emailDoneTrigger = PassthroughSubject<Void, Never>()
        
        let validatePasswordTrigger = PassthroughSubject<String, Never>()
        let confirmPasswordTrigger = PassthroughSubject<String, Never>()
        let passwordDoneTrigger = PassthroughSubject<Void, Never>()
        
        let validateNicknameTrigger = PassthroughSubject<String, Never>()
        let validatePhoneNumTrigger = PassthroughSubject<String, Never>()
        let InfoDoneTrigger = PassthroughSubject<Void, Never>()
    }
    
    struct Output {
        var state: State = .email
        var emailErrorMessage = ""
        var emailDoneButtonDisable = true
        
        var passwordErrorMessage = ""
        var passwordConfirmErrorMessage = ""
        var passwordDoneButtonDisable = true
        
        var nicknameErrorMassage = ""
        var phoneNumErrorMessage = ""
        var infoDoneButtonDisable = true
    }
    
    func transform() {
        input.validateEmailTrigger
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink(with: self) { owner, email in
                owner.signUpParam.email = email
                owner.validateEmail(email)
            }
            .store(in: &cancellables)
        
        input.emailDoneTrigger
            .sink { [weak self] _ in
                guard let self else { return }
                output.state = .password
            }
            .store(in: &cancellables)
        
        input.validatePasswordTrigger
            .sink { [weak self] password in
                guard let self else { return }
                signUpParam.password = password
                output.passwordDoneButtonDisable = !validateBothPassword(
                    password: signUpParam.password,
                    confirmPassword: signUpParam.confirmPassword
                )
            }
            .store(in: &cancellables)
        
        input.confirmPasswordTrigger
            .sink { [weak self] password in
                guard let self else { return }
                signUpParam.confirmPassword = password
                output.passwordDoneButtonDisable = !validateBothPassword(
                    password: signUpParam.password,
                    confirmPassword: signUpParam.confirmPassword
                )
            }
            .store(in: &cancellables)
        
        input.passwordDoneTrigger
            .sink { [weak self] _ in
                guard let self else { return }
                output.state = .info
            }
            .store(in: &cancellables)
        
        input.validateNicknameTrigger
            .sink { [weak self] nickname in
                guard let self else { return }
                signUpParam.nickname = nickname
                output.infoDoneButtonDisable = !validateInfo(nickname: signUpParam.nickname, phoneNum: signUpParam.phoneNum)
            }
            .store(in: &cancellables)
        
        input.validatePhoneNumTrigger
            .sink { [weak self] phoneNum in
                guard let self else { return }
                signUpParam.phoneNum = phoneNum
                output.infoDoneButtonDisable = !validateInfo(nickname: signUpParam.nickname, phoneNum: signUpParam.phoneNum)
            }
            .store(in: &cancellables)
        
        input.InfoDoneTrigger
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .flatMap { [weak self] _ -> AnyPublisher<Result<JoinResponse, NetworkError<UserErrorResponse>>, Never> in
                guard let self else { return AnyPublisher(Just(.failure(.server(UserErrorResponse(message: ""))))) }
                return userRepository.signup(signUpParam)
            }
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    // TODO: accessToken, refreshToken 받아서 처리
                    dump(success)
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - 이메일
extension SignUpViewModel {
    private func validateEmail(_ email: String) {
        if email.isEmpty {
            output.emailErrorMessage = ""
            output.emailDoneButtonDisable = true
        } else if !email.isValidEmail() {
            output.emailErrorMessage = "유효한 이메일 주소를 입력해주세요."
            output.emailDoneButtonDisable = true
        } else {
            let publisher = userRepository.validateEmail(email)
            publisher
                .receive(on: DispatchQueue.main)
                .sink(with: self) { owner, result in
                    switch result {
                    case .success:
                        owner.output.emailErrorMessage = ""
                        owner.output.emailDoneButtonDisable = false
                    case .failure(let failure):
                        if case let NetworkError<UserErrorResponse>.server(serverError) = failure {
                            owner.output.emailErrorMessage = serverError.message
                        } else {
                            owner.output.emailErrorMessage = ""
                        }
                        owner.output.emailDoneButtonDisable = true
                    }
                }
                .store(in: &cancellables)
        }
    }
}

// MARK: - 비밀번호
extension SignUpViewModel {
    private func validateBothPassword(password: String, confirmPassword: String) -> Bool {
        return validatePassword(password) && validateConfirmPassword(password: password, confirmPassword: confirmPassword)
    }
    
    private func validatePassword(_ password: String) -> Bool {
        if password.isEmpty {
            output.passwordErrorMessage = ""
            return false
        } else {
            let detail = password.passwordValidationDetails()
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
    
    private func validateConfirmPassword(password: String, confirmPassword: String) -> Bool {
        if password.isEmpty || confirmPassword.isEmpty {
            output.passwordConfirmErrorMessage = ""
            return false
        } else if password == confirmPassword {
            output.passwordConfirmErrorMessage = ""
            return true
        } else {
            output.passwordConfirmErrorMessage = "비밀번호가 일치하지 않습니다."
            return false
        }
    }
}

// MARK: - 회원 정보
extension SignUpViewModel {
    private func validateInfo(nickname: String, phoneNum: String) -> Bool {
        return validateNickname(nickname) && validatePhoneNum(phoneNum)
    }
    
    private func validateNickname(_ nickname: String) -> Bool {
        if nickname.isEmpty {
            output.nicknameErrorMassage = ""
            return false
        } else if nickname.isValidNickname() {
            output.nicknameErrorMassage = ".,?*-@ 한 글자로 구성할 수 없습니다"
            return false
        } else {
            output.nicknameErrorMassage = ""
            return true
        }
    }
    
    private func validatePhoneNum(_ phoneNum: String) -> Bool {
        if phoneNum.isEmpty {
            output.phoneNumErrorMessage = ""
            return true
        }
        let prefix = phoneNum.prefix(3)
        let isValid = (prefix == "010" && phoneNum.count == 11) ||
        (["011", "016", "017", "018", "019"].contains(String(prefix)) && phoneNum.count == 10)
        output.phoneNumErrorMessage = isValid ? "" : "전화번호를 정확히 입력해주세요"
        
        return isValid
    }
}

extension SignUpViewModel {
    enum Action {
        // 이메일
        case validateEmail(_ email: String)
        case emailDone
        // 비밀번호
        case validatePassword(_ password: String)
        case confirmPassword(_ confirmPassword: String)
        case passwordDone
        // 회원정보
        case validateNickname(_ nickname: String)
        case validatePhoneNum(_ phoneNum: String)
        case infoDone
    }
    
    func action(_ action: Action) {
        switch action {
        case .validateEmail(let email):
            input.validateEmailTrigger
                .send(email)
        case .emailDone:
            input.emailDoneTrigger
                .send(())
        case .validatePassword(let password):
            input.validatePasswordTrigger
                .send(password)
        case .confirmPassword(let confirmPassword):
            input.confirmPasswordTrigger
                .send(confirmPassword)
        case .passwordDone:
            input.passwordDoneTrigger
                .send(())
        case .validateNickname(let nickname):
            input.validateNicknameTrigger
                .send(nickname)
        case .validatePhoneNum(let phoneNum):
            input.validatePhoneNumTrigger
                .send((phoneNum))
        case .infoDone:
            input.InfoDoneTrigger
                .send(())
        }
    }
}
