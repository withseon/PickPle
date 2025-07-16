//
//  AppError.swift
//  PickPle
//
//  Created by Claude on 1/25/25.
//

import Foundation

enum AppError: Error {
    case tokenExpired
    case networkError(String)
    case serverError(String)
    case unknownError(String)
}

extension AppError {
    var message: String {
        switch self {
        case .tokenExpired:
            return "로그인이 만료되어 다시 로그인해주세요."
        case .networkError(let message):
            return message
        case .serverError(let message):
            return message
        case .unknownError(let message):
            return message
        }
    }
}