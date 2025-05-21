//
//  NetworkError.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

enum NetworkError<T: ErrorResponseType>: Error {
    case alamofire(_ error: AFError)
    case decoding(_ error: Error)
    case server(error: T, statusCode: Int)
    case decodingServer(error: Error, statusCode: Int)
}

extension NetworkError {
    var message: String {
        switch self {
        case .server(let error, _):
            return error.message
        default:
            return "네트워크 에러 발생"
        }
    }
    
    var debugMessage: String {
        switch self {
        case .alamofire(let error):
            return "❌ Network Error:: alamofire - \(error)"
        case .decoding(let error):
            return "❌ Network Error:: Decoding - \(error)"
        case .server(let error, let statusCode):
            return "❌ Network Error:: serverError(statusCode: \(statusCode) - \(error)"
        case .decodingServer(let error, let statusCode):
            return "❌ Network Error:: decodingServer(statusCode: \(statusCode) - \(error)"
        }
    }
}
