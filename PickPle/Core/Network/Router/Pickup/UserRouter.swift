//
//  UserRouter.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

struct AppleLoginRequest: RequestableType {
    let idToken: String
    let deviceToken: String
    let nick: String
}

struct UpdateProfileRequest: RequestableType {
    let nick: String?
    let phoneNum: String?
    let profileImage: String?
}

struct profileImageResponse: Decodable {
    let profileImage: String
}

enum UserRouter {
    case validateEmail(_ request: ValidationEmailRequest)
    case joinEmail(_ request: JoinRequest)
    case emailLogin(_ request: EmailLoginRequest)
    case kakaoLogin(_ request: KakaoLoginRequest)
    case appleLogin(_ request: AppleLoginRequest)
    case logout
    case deviceToken(_ request: DeviceTokenRequest)
    case myProfile
    case updateProfile(_ request: UpdateProfileRequest)
    case uploadProfileImage
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
        case .appleLogin:
            return "/v1/users/login/apple"
        case .logout:
            return "/v1/users/logout"
        case .deviceToken:
            return "/v1/users/deviceToken"
        case .myProfile, .updateProfile:
            return "/v1/users/me/profile"
        case .uploadProfileImage:
            return "/v1/users/profile/images"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .myProfile:
            return .get
        case .validateEmail, .joinEmail, .emailLogin, .kakaoLogin, .appleLogin, .logout, .uploadProfileImage:
            return .post
        case .deviceToken, .updateProfile:
            return .put
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
        case .appleLogin(let request):
            return .body(request)
        case .logout:
            return nil
        case .deviceToken(let request):
            return .body(request)
        case .myProfile:
            return nil
        case .updateProfile(let request):
            return .body(request)
        case .uploadProfileImage:
            return nil
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        case .uploadProfileImage:
            return nil
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
