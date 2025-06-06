//
//  NetworkError.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

enum NetworkError: Error {
    case alamofire(_ error: AFError)
    case server(_ error: ErrorResponseType)
    case expired
    case unknown(_ error: Error)
}

extension NetworkError {
    var message: String {
        switch self {
        case .server(let error):
            return error.message
        case .expired:
            return "로그인 정보가 만료되었습니다\n다시 로그인해주세요"
        default:
            return "네트워크 에러 발생"
        }
    }
    
    var debugMessage: String {
        switch self {
        case .alamofire(let error):
            return "❌ Network Error:: alamofire - \(error)"
        case .server(let error):
            return "❌ Network Error:: serverError - \(error)"
        case .expired:
            return "❌ Network Error:: refresh Token expired"
        case .unknown(let error):
            return "❌ Network Error:: Unknown - \(error)"
        }
    }
}
