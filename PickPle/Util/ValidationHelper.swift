//
//  ValidationHelper.swift
//  PickPle
//
//  Created by 정인선 on 8/16/25.
//

import Foundation

enum ValidationHelper {
    // MARK: - 닉네임 검증
    static func validateNickname(_ nickname: String) -> ValidationResult {
        if nickname.isEmpty {
            return .failure(.emptyNickname)
        } else if nickname.isValidNickname() {
            return .failure(.invalidNicknameCharacters)
        } else {
            return .success(nickname)
        }
    }
    
    // MARK: - 핸드폰 번호 검증
    static func validatePhoneNumber(_ phoneNumber: String) -> ValidationResult {
        if phoneNumber.isEmpty {
            return .failure(.emptyPhoneNumber)
        }
        
        let prefix = phoneNumber.prefix(3)
        let isValid = (prefix == "010" && phoneNumber.count == 11) ||
                      (["011", "016", "017", "018", "019"].contains(String(prefix)) && phoneNumber.count == 10)
        
        if isValid {
            return .success(phoneNumber)
        } else {
            return .failure(.invalidPhoneNumberFormat)
        }
    }
    
    // MARK: - 회원 정보 통합 검증
    static func validateUserInfo(nickname: String, phoneNumber: String) -> UserInfoValidationResult {
        let nicknameResult = validateNickname(nickname)
        let phoneResult = validatePhoneNumber(phoneNumber)
        
        return UserInfoValidationResult(
            nickname: nicknameResult,
            phoneNumber: phoneResult
        )
    }
}

// MARK: - 검증 결과 타입
enum ValidationResult {
    case success(String)
    case failure(ValidationError)
    
    var isValid: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var value: String? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
    
    var errorMessage: String {
        switch self {
        case .success: return ""
        case .failure(let error): return error.message
        }
    }
}

// MARK: - 사용자 정보 검증 결과
struct UserInfoValidationResult {
    let nickname: ValidationResult
    let phoneNumber: ValidationResult
    
    var isValid: Bool {
        return nickname.isValid && phoneNumber.isValid
    }
    
    var nicknameErrorMessage: String {
        return nickname.errorMessage
    }
    
    var phoneNumberErrorMessage: String {
        return phoneNumber.errorMessage
    }
}

// MARK: - 검증 에러 타입
enum ValidationError: Error {
    case emptyNickname
    case invalidNicknameCharacters
    case emptyPhoneNumber
    case invalidPhoneNumberFormat
    
    var message: String {
        switch self {
        case .emptyNickname:
            return ""
        case .invalidNicknameCharacters:
            return ".,?*-@ 한 글자로 구성할 수 없습니다"
        case .emptyPhoneNumber:
            return ""
        case .invalidPhoneNumberFormat:
            return "전화번호를 정확히 입력해주세요"
        }
    }
}
