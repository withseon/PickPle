//
//  ChatResponse.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import Foundation

struct ChatResponse: Decodable {
    var chatId: String
    var roomId: String
    var content: String
    var createdAt: String
    var updatedAt: String
    var sender: UserInfoResponse
    var files: [String]
}

extension ChatResponse {
    var asChatMessage: ChatMessage {
        return ChatMessage(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: FormatHelper.shared.getChatTime(from: createdAt),
            updatedAt: "",
            sender: UserInfo(
                userId: sender.userId,
                nickname: sender.nick,
                profileImage: sender.profileImage
            ),
            files: files,
            createdAtUTC: createdAt
        )
    }
}
