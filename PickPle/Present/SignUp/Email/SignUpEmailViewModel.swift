//
//  SignUpEmailViewModel.swift
//  PickPle
//
//  Created by 정인선 on 5/11/25.
//

import Foundation
import Combine

final class SignUpEmailViewModel: ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()

    init() {
        transform()
    }

    deinit {
        print("SignUpEmailViewModel deinit")
    }
}

// MARK: - Input/Output
extension SignUpEmailViewModel {
    struct Input {
        var email = ""
        let validateEmailTrigger = PassthroughSubject<Void, Never>()
    }

    struct Output {
        var emailErrorMessage = ""
        var nextButtonDisable = true
    }

    func transform() {
        input.validateEmailTrigger
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                output.nextButtonDisable = !validateEmail()
            }
            .store(in: &cancellables)
    }
    
    private func validateEmail() -> Bool {
        if input.email.isEmpty {
            output.emailErrorMessage = ""
            return false
        } else if !input.email.isValidEmail() {
            output.emailErrorMessage = "유효한 이메일 주소를 입력해주세요."
            return false
        } else {
            if isEmailAlreadyRegistered() {
                output.emailErrorMessage = "이미 사용중인 이메일입니다."
                return false
            } else {
                output.emailErrorMessage = ""
                return true
            }
        }
    }
    
    private func isEmailAlreadyRegistered() -> Bool {
        // TODO: 이메일 중복 확인
        return false
    }
}

// MARK: - Action
extension SignUpEmailViewModel {
    enum Action {
        case validateEmail
    }

    func action(_ action: Action) {
        switch action {
        case .validateEmail:
            input.validateEmailTrigger
                .send(())
        }
    }
}
