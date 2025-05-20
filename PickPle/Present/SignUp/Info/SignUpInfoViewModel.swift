//
//  SignUpInfoViewModel.swift
//  PickPle
//
//  Created by 정인선 on 5/12/25.
//

import Foundation
import Combine

final class SignUpInfoViewModel: ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()

    init() {
        transform()
    }

    deinit {
        print("SignUpInfoViewModel deinit")
    }
}

// MARK: - Input/Output
extension SignUpInfoViewModel {
    struct Input {
        var nickname = ""
        var phoneNum = ""
        let validateNicknameTrigger = PassthroughSubject<Void, Never>()
        let validatePhoneNumTrigger = PassthroughSubject<Void, Never>()
    }
    
    struct Output {
        var nicknameErrorMassage = ""
        var phoneNumErrorMessage = ""
        var nextButtonDisable = true
    }
    
    func transform() {
        input.validateNicknameTrigger
            .merge(with: input.validatePhoneNumTrigger)
            .sink { [weak self] _ in
                guard let self else { return }
                let validNickname = validNickname(input.nickname)
                let validPhoneNum = validPhoneNum(input.phoneNum)
                output.nextButtonDisable = !validNickname || !validPhoneNum
            }
            .store(in: &cancellables)
    }
    
    private func validNickname(_ text: String) -> Bool {
        if text.isEmpty {
            output.nicknameErrorMassage = ""
            return false
        } else if text.isValidNickname() {
            output.nicknameErrorMassage = "\(input.nickname) 한 글자로 구성할 수 없습니다"
            return false
        } else {
            output.nicknameErrorMassage = ""
            return true
        }
    }
    
    private func validPhoneNum(_ text: String) -> Bool {
        if text.isEmpty {
            output.phoneNumErrorMessage = ""
            return true
        }
        let prefix = text.prefix(3)
        let isValid = (prefix == "010" && text.count == 11) ||
        (["011", "016", "017", "018", "019"].contains(String(prefix)) && text.count == 10)
        output.phoneNumErrorMessage = isValid ? "" : "전화번호를 정확히 입력해주세요"
        
        return isValid
    }
}

// MARK: - Action
extension SignUpInfoViewModel {
    enum Action {
        case validateNickname
        case validatePhoneNum
    }

    func action(_ action: Action) {
        switch action {
        case .validateNickname:
            input.validateNicknameTrigger
                .send(())
        case .validatePhoneNum:
            input.validatePhoneNumTrigger
                .send(())
        }
    }
}
