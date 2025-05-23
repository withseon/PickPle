//
//  NetworkError.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

enum NetworkError<E: ErrorResponseType>: Error {
    case alamofire(_ error: AFError)
    case server(_ error: E)
    case unknown(_ error: Error)
}

extension NetworkError {
    var message: String {
        switch self {
        case .server(let error):
            return error.message
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
        case .unknown(let error):
            return "❌ Network Error:: Unknown - \(error)"
        }
    }
}
