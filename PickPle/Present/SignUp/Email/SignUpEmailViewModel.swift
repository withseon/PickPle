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
                validateEmail { [weak self] isValid in
                    guard let self else { return }
                    output.nextButtonDisable = !isValid
                }
            }
            .store(in: &cancellables)
    }
    
    private func validateEmail(_ completion: @escaping (Bool) -> Void) {
        if input.email.isEmpty {
            output.emailErrorMessage = ""
            completion(false)
        } else if !input.email.isValidEmail() {
            output.emailErrorMessage = "유효한 이메일 주소를 입력해주세요."
            completion(false)
        } else {
            isEmailAlreadyRegistered { [weak self] isAlready, message in
                guard let self else { return }
                output.emailErrorMessage = message
                completion(!isAlready)
            }
        }
    }
    
    private func isEmailAlreadyRegistered(_ completion: @escaping (Bool, String) -> Void) {
        NetworkManager.executeFetch(target: UserRouter.validateEmail(ValidationEmailRequest(email: input.email)), responseType: MessageResponse.self, errorType: UserErrorResponse.self)
            .sink { result in
                switch result {
                case .success(_):
                    completion(false, "")
                case .failure(let failure):
                    completion(true, failure.message)
                    print(failure.debugMessage)
                }
            }
            .store(in: &cancellables)
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
