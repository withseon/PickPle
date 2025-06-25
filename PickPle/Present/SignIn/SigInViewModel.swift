//
//  SigInViewModel.swift
//  PickPle
//
//  Created by 정인선 on 5/11/25.
//

import Foundation
import Combine
import KakaoSDKUser

final class SignInViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    private var signInParam = SignInParam.empty
    private let userRepository: UserRepository
    
    enum FieldType {
        case email, password
    }

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        super.init()
        transform()
    }
}

// MARK: - Input/Output
extension SignInViewModel {
    struct Input {
        let validateEmailTrigger = PassthroughSubject<String, Never>()
        let validatePasswordTrigger = PassthroughSubject<String, Never>()
        let loginValidateTrigger = PassthroughSubject<Void, Never>()
        let kakaoLoginTrigger = PassthroughSubject<Void, Never>()
    }

    struct Output {
        var emailErrorMessage = ""
        var passwordErrorMessage = ""
        let setFocusState = CurrentValueSubject<FieldType?, Never>(nil)
        var pushMainTrigger = PassthroughSubject<Void, Never>()
    }

    func transform() {
        input.validateEmailTrigger
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] email in
                guard let self else { return }
                signInParam.email = email
                validateEmail(email)
            }
            .store(in: &cancellables)
        
        input.validatePasswordTrigger
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] password in
                guard let self else { return }
                signInParam.password = password
                validatePassword(password)
            }
            .store(in: &cancellables)
        
        input.loginValidateTrigger
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                let validateEmail = validateEmail(signInParam.email)
                let validatePassword = validatePassword(signInParam.password)
                
                if !validateEmail {
                    output.setFocusState
                        .send(.email)
                } else if !validatePassword {
                    output.setFocusState
                        .send(output.passwordErrorMessage.isEmpty ? nil : .password)
                } else {
                    output.setFocusState
                        .send(nil)
                    signInEmail()
                }
            }
            .store(in: &cancellables)
        
        input.kakaoLoginTrigger
            .sink(with: self) { owner, _ in
                if (UserApi.isKakaoTalkLoginAvailable()) {
                    owner.kakaoLonginWithApp()
                } else {
                    owner.kakaoLoginWithAccount()
                }
            }
            .store(in: &cancellables)
    }
    
    @discardableResult
    private func validateEmail(_ email: String) -> Bool {
        if email.isEmpty {
            output.emailErrorMessage = "이메일을 입력해주세요."
            return false
        } else if !email.isValidEmail() {
            output.emailErrorMessage = "유효한 이메일 주소를 입력해주세요."
            return false
        } else {
            output.emailErrorMessage = ""
            return true
        }
    }
    
    @discardableResult
    private func validatePassword(_ password: String) -> Bool {
        if password.isEmpty {
            output.passwordErrorMessage = "비밀번호를 입력해주세요."
            return false
        } else if !password.isValidPassword() {
            output.passwordErrorMessage = ""
            return false
        } else {
            output.passwordErrorMessage = ""
            return true
        }
    }
    
    private func signInEmail() {
        let publisher = userRepository.loginEmail(signInParam)
        print(#function)
        publisher
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(_):
                    owner.output.pushMainTrigger
                        .send(())
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func kakaoLonginWithApp() {
        UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
            guard let self else { return }
            if let error {
                print(#function, error)
            }
            else {
                if let accessToken = oauthToken?.accessToken {
                    singInKakao(accessToken)
                }
            }
        }
    }
    
    private func kakaoLoginWithAccount() {
        UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
            guard let self else { return }
            if let error = error {
                print(#function, error)
            }
            else {
                if let idToken = oauthToken?.idToken {
                    singInKakao(idToken)
                }
            }
        }
    }
    
    private func singInKakao(_ accessToken: String) {
        let publish = userRepository.loginKakako(accessToken)
        publish
            .sink(with: self) { owner, result in
                switch result {
                case .success(_):
                    owner.output.pushMainTrigger
                        .send(())
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Action
extension SignInViewModel {
    enum Action {
        case validateEmail(_ email: String)
        case validatePassword(_ password: String)
        case loginButtonTapped
        case kakaoLoginButtonTapped
    }

    func action(_ action: Action) {
        switch action {
        case .validateEmail(let email):
            input.validateEmailTrigger
                .send(email)
        case .validatePassword(let password):
            input.validatePasswordTrigger
                .send(password)
        case .loginButtonTapped:
            input.loginValidateTrigger
                .send(())
        case .kakaoLoginButtonTapped:
            input.kakaoLoginTrigger
                .send(())
        }
    }
}
