//
//  PostRouter.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation
import Alamofire

enum PostRouter {
    case posts(_ request: PostSummaryRequest)
    case userPosts(_ request: UserPostsRequest)
}

extension PostRouter: TargetType {
    var baseURL: String {
        switch self {
        default:
            return APIURL.PICKUP
        }
    }
    
    var path: String {
        switch self {
        case .posts:
            return "/v1/posts/geolocation"
        case .userPosts(let request):
            return "/v1/posts/users/\(request.userId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .posts, .userPosts:
            return .get
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .posts(let request):
            return .query(request)
        case .userPosts(let request):
            return .query(request)
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        default:
            return nil
        }
    }
}
