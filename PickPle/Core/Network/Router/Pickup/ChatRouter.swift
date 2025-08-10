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
    case sendFile(roomId: String)
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
        case .sendFile(let roomId):
            return "/v1/chats/\(roomId)/files"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .chatRoom, .sendChat, .sendFile:
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
        case .sendFile:
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
