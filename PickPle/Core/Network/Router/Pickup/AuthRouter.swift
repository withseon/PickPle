//
//  AuthRouter.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation
import Alamofire

enum AuthRouter {
    case refresh(_ refreshToken: String)
}

extension AuthRouter: TargetType {
    var baseURL: String {
        switch self {
        case .refresh:
            return APIURL.PICKUP
        }
    }
    
    var path: String {
        switch self {
        case .refresh:
            return "/v1/auth/refresh"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .refresh:
            return .get
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .refresh:
            return nil
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        case .refresh(let refreshToken):
            return ["RefreshToken": refreshToken]
        }
    }
}
