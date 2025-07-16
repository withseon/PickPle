//
//  BannerRouter.swift
//  PickPle
//
//  Created by 정인선 on 8/1/25.
//

import Foundation
import Alamofire

enum BannerRouter {
    case banner
}

extension BannerRouter: TargetType {
    var baseURL: String {
        switch self {
        default:
            return APIURL.PICKUP
        }
    }
    
    var path: String {
        switch self {
        case .banner:
            return "/v1/banners/main"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .banner:
            return .get
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .banner:
            return nil
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        case .banner:
            return ["Content-Type": "application/json"]
        }
    }
}
