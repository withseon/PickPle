//
//  ChatMessageTable.swift
//  PickPle
//
//  Created by 정인선 on 7/21/25.
//

import Foundation
import RealmSwift

final class ChatMessageTable: Object {
    @Persisted(primaryKey: true) var chatId: String
    @Persisted var roomId: String
    @Persisted var content: String
    @Persisted var createdAt: String
    @Persisted var _files: List<String>
    @Persisted var senderID: String
    @Persisted var senderNick: String
    
    var files: [String] {
           get { return Array(_files) }
           set {
               _files.removeAll()
               _files.append(objectsIn: newValue)
           }
    }
    
    convenience init(
        chatId: String,
        roomId: String,
        content: String,
        createdAt: String,
        files: [String],
        senderID: String,
        senderNick: String
    ) {
        self.init()
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.createdAt = createdAt
        self.files = files
        self.senderID = senderID
        self.senderNick = senderNick
    }
}

extension ChatMessageTable {
    static func from(_ response: ChatResponse) -> ChatMessageTable {
        return ChatMessageTable(
            chatId: response.chatId,
            roomId: response.roomId,
            content: response.content,
            createdAt: response.createdAt,
            files: response.files,
            senderID: response.sender.userId,
            senderNick: response.sender.nick
        )
    }
    
    var asChatMessage: ChatMessage {
        return ChatMessage(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: FormatHelper.shared.getChatTime(from: createdAtUTC),
            updatedAt: "",
            sender: UserInfo(
                userId: senderID,
                nickname: senderNick,
                profileImage: nil),
            files: files,
            createdAtUTC: createdAt // 원본 UTC 시간 저장
        )
    }
    
    // 원본 UTC 시간을 반환하는 computed property
    var createdAtUTC: String {
        return createdAt
    }
}
