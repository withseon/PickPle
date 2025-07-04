//
//  ChatRoomResponse.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import Foundation

struct ChatRoomResponse: Decodable {
    struct UserInfoResponse: Decodable {
        var userId: String
        var nick: String
        var profileImage: String?
    }
    
    struct ChatResponse: Decodable {
        var chatId: String
        var roomId: String
        var content: String
        var createdAt: String
        var updatedAt: String
        var sender: UserInfoResponse
        var files: [String]
    }
    
    var roomId: String
    var createdAt: String
    var updatedAt: String
    var participants: [UserInfoResponse]
    var lastChat: ChatResponse?
}

extension ChatRoomResponse {
    var asChatRoomThumbnail: ChatRoomThumbnail {
        return ChatRoomThumbnail(
            roomId: roomId,
            updatedAt: FormatHelper.shared.getChatTime(from: updatedAt),
            lastChat: lastChat?.content ?? "",
            userId: participants.filter { $0.userId != UserDefaultsManager.userId }.first!.userId,
            nick: participants.filter { $0.userId != UserDefaultsManager.userId }.first!.nick,
            profileImage: participants.filter { $0.userId != UserDefaultsManager.userId }.first!.profileImage
        )
    }
}
