//
//  KeyChainError.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

enum KeychainError: Error {
    case duplicateItem
    case itemNotFound
    case authFailed
    case invalidParameter
    case diskFull
    case unknown(OSStatus)
    
    var errorMessage: String {
        switch self {
        case .duplicateItem:
            return "이미 저장된 데이터가 있습니다\n새로운 데이터로 업데이트해주세요"
        case .itemNotFound:
            return "저장된 데이터를 찾을 수 없습니다\n다시 시도해주세요"
        case .authFailed:
            return "보안 인증에 실패했습니다\n잠시 후 다시 시도해주세요"
        case .invalidParameter:
            return "올바르지 않은 요청입니다\n문제가 지속되면 문의해주세요"
        case .diskFull:
            return "저장 공간이 부족합니다\n사용하지 않는 파일을 삭제하고 다시 시도해주세요"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다\n문제가 지속되면 문의해주세요"
        }
    }
    
    static func parse(_ status: OSStatus) -> KeychainError {
        switch status {
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecItemNotFound:
            return .itemNotFound
        case errSecAuthFailed:
            return .authFailed
        case errSecParam:
            return .invalidParameter
        case errSecDiskFull:
            return .diskFull
        default:
            return .unknown(status)
        }
    }
}
