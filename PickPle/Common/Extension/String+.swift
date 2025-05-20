//
//  String+.swift
//  PickPle
//
//  Created by 정인선 on 5/12/25.
//

import Foundation

extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    func isValidPassword() -> Bool {
        let passwordRegex = #"^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,20}$"#
        let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegex)
        return passwordPred.evaluate(with: self)
    }
    
    // 8자 이상 20자 이하인지 확인
    private func isLengthValid() -> Bool {
        return self.count >= 8 && self.count <= 20
    }
    
    // 영문자를 포함하는지 확인
    private func containsLetters() -> Bool {
        let letterRegex = "[A-Za-z]"
        return self.range(of: letterRegex, options: .regularExpression) != nil
    }
    
    // 숫자를 포함하는지 확인
    private func containsDigits() -> Bool {
        let digitRegex = "\\d"
        return self.range(of: digitRegex, options: .regularExpression) != nil
    }
    
    // 특수문자를 포함하는지 확인
    private func containsSpecialCharacters() -> Bool {
        let specialCharRegex = "[@$!%*#?&]"
        return self.range(of: specialCharRegex, options: .regularExpression) != nil
    }
    
    // 비밀번호 유효성 검사 결과를 상세하게 반환
    func passwordValidationDetails() -> (isValid: Bool, lengthValid: Bool, hasLetters: Bool, hasDigits: Bool, hasSpecial: Bool) {
        let lengthValid = isLengthValid()
        let hasLetters = containsLetters()
        let hasDigits = containsDigits()
        let hasSpecial = containsSpecialCharacters()
        
        let isValid = lengthValid && hasLetters && hasDigits && hasSpecial
        
        return (isValid, lengthValid, hasLetters, hasDigits, hasSpecial)
    }

}
