//
//  ChatRouter.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import Foundation
import Alamofire

enum ChatRouter {
    case chatRoom(_ request: ChatRoomRequest)
    case chatRoomList
    case sendChat(roomId: String, request: SendChatRequest)
    case chatMessage(roomId: String, request: ChatMessageRequest)
}

extension ChatRouter: TargetType {
    var baseURL: String {
        switch self {
        default:
            return APIURL.PICKUP
        }
    }
    
    var path: String {
        switch self {
        case .chatRoom, .chatRoomList:
            return "/v1/chats"
        case .sendChat(let roomId, _):
            return "/v1/chats/\(roomId)"
        case .chatMessage(let roomId, _):
            return "/v1/chats/\(roomId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .chatRoom, .sendChat:
            return .post
        case .chatRoomList, .chatMessage:
            return .get
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .chatRoom(let request):
            return .body(request)
        case .chatRoomList:
            return nil
        case .sendChat(_, let request):
            return .body(request)
        case .chatMessage(_, let request):
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
