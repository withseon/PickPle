//
//  PostRouter.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation
import Alamofire

enum PostRouter {
    case posts(_ Request: PostSummaryRequest)
}

extension PostRouter: TargetType {
    var baseURL: String {
        switch self {
        case .posts:
            return APIURL.PICKUP
        }
    }
    
    var path: String {
        switch self {
        case .posts:
            return "/v1/posts/geolocation"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .posts:
            return .get
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .posts(let request):
            return .body(request)
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        default:
            return nil
        }
    }
}
