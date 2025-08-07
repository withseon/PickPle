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
    case postDetail(postId: String)
    case sendFile
    case createPost(_ request: CreatePostRequest)
    case updatePost(postId: String, request: UpdatePostRequest)
    case deletePost(_ postId: String)
    case createComment(postId: String, request: CreateCommentRequest)
    case updateComment(postId: String, commentId: String, request: UpdateCommentRequest)
    case deleteComment(postId: String, commentId: String)
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
        case .postDetail(let postId):
            return "/v1/posts/\(postId)"
        case .sendFile:
            return "/v1/posts/files"
        case .createPost:
            return "/v1/posts"
        case .updatePost(let postId, _):
            return "/v1/posts/\(postId)"
        case .deletePost(let postId):
            return "/v1/posts/\(postId)"
        case .createComment(let postId, _):
            return "/v1/posts/\(postId)/comments"
        case .updateComment(let postId, let commentId, _):
            return "/v1/posts/\(postId)/comments/\(commentId)"
        case .deleteComment(let postId, let commentId):
            return "/v1/posts/\(postId)/comments/\(commentId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .posts, .userPosts, .postDetail:
            return .get
        case .sendFile, .createPost, .createComment:
            return .post
        case .updatePost, .updateComment:
            return .put
        case .deletePost, .deleteComment:
            return .delete
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .posts(let request):
            return .query(request)
        case .userPosts(let request):
            return .query(request)
        case .createPost(let request):
            return .body(request)
        case .updatePost(_, let request):
            return .body(request)
        case .createComment(_, let request):
            return .body(request)
        case .updateComment(_, _, let request):
            return .body(request)
        case .postDetail, .sendFile, .deletePost, .deleteComment:
            return nil
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        case .sendFile:
            return nil
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
