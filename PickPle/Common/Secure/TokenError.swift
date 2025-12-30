//
//  TokenError.swift
//  PickPle
//
//  Created by 정인선 on 8/29/25.
//

import Foundation

enum TokenError: Error {
    case encodingFailed
    case decodingFailed
    case tokenNotFound
    case deviceLocked
    case keychainAccessDenied
    case duplicateItem
    case unknown(OSStatus)

    /// OSStatus를 의미 있는 TokenError로 변환
    init(status: OSStatus) {
        switch status {
        case errSecItemNotFound:
            self = .tokenNotFound
        case errSecInteractionNotAllowed:
            self = .deviceLocked
        case errSecMissingEntitlement:
            self = .keychainAccessDenied
        case errSecDuplicateItem:
            self = .duplicateItem
        default:
            self = .unknown(status)
        }
    }

    var localizedDescription: String {
        switch self {
        case .encodingFailed:
            return "토큰 인코딩 실패"
        case .decodingFailed:
            return "토큰 디코딩 실패"
        case .tokenNotFound:
            return "토큰을 찾을 수 없습니다"
        case .deviceLocked:
            return "디바이스가 잠겨있어 토큰에 접근할 수 없습니다"
        case .keychainAccessDenied:
            return "키체인 접근 권한이 없습니다"
        case .duplicateItem:
            return "이미 존재하는 토큰입니다"
        case .unknown(let status):
            return "알 수 없는 키체인 에러: \(status)"
        }
    }
}
