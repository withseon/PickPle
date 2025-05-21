//
//  UserRouter.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

enum UserRouter {
    case validateEmail(_ request: ValidationEmailRequest)
    case joinEmail(_ request: JoinRequest)
}

extension UserRouter: TargetType {
    var baseURL: String {
        switch self {
        default:
            return APIURL.PICKUP
        }
    }
    
    var path: String {
        switch self {
        case .validateEmail:
            return "/v1/users/validation/email"
        case .joinEmail:
            return "/v1/users/join"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .validateEmail, .joinEmail:
            return .post
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .validateEmail(let request):
            return .body(request)
        case .joinEmail(let request):
            return .body(request)
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        case .validateEmail, .joinEmail:
            return nil
        }
    }
}
