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
    case emailLogin(_ request: EmailLoginRequest)
    case kakaoLogin(_ request: KakaoLoginRequest)
    case myProfile
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
        case .emailLogin:
            return "/v1/users/login"
        case .kakaoLogin:
            return "/v1/users/login/kakao"
        case .myProfile:
            return "v1/users/me/profile"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .myProfile:
            return .get
        case .validateEmail, .joinEmail, .emailLogin, .kakaoLogin:
            return .post
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .validateEmail(let request):
            return .body(request)
        case .joinEmail(let request):
            return .body(request)
        case .emailLogin(let request):
            return .body(request)
        case .kakaoLogin(let request):
            return .body(request)
        case .myProfile:
            return nil
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        case .validateEmail, .joinEmail, .emailLogin, .kakaoLogin, .myProfile:
            return nil
        }
    }
}
