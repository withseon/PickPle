//
//  ChatRoomTable.swift
//  PickPle
//
//  Created by 정인선 on 7/21/25.
//

import Foundation
import RealmSwift

final class ChatRoomTable: Object {
    @Persisted(primaryKey: true) var roomID: String
    @Persisted var createdAt: String
    @Persisted var updatedAt: String?
    
    @Persisted var opponentID: String
    @Persisted var opponentNick: String

    @Persisted var lastMessageID: String
    @Persisted var lastMessageContent: String
    @Persisted var lastMessageCreatedAt: String
    @Persisted var lastMessageSenderID: String
    @Persisted var lastMessageFiles: List<String>
    
    convenience init(
        roomID: String,
        createdAt: String,
        updatedAt: String? = nil,
        opponentID: String,
        opponentNick: String,
        lastMessageID: String,
        lastMessageContent: String,
        lastMessageCreatedAt: String,
        lastMessageSenderID: String,
        lastMessageFiles: List<String>
    ) {
        self.init()
        self.roomID = roomID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.opponentID = opponentID
        self.opponentNick = opponentNick
        self.lastMessageID = lastMessageID
        self.lastMessageContent = lastMessageContent
        self.lastMessageCreatedAt = lastMessageCreatedAt
        self.lastMessageSenderID = lastMessageSenderID
        self.lastMessageFiles = lastMessageFiles
    }
}

extension ChatRoomTable {
    static func from(_ response: ChatRoomResponse) -> ChatRoomTable {
        let fileList = List<String>()
        fileList.append(objectsIn: response.lastChat?.files ?? [])
        
        return ChatRoomTable(
            roomID: response.roomId,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt,
            opponentID: response.participants[0].userId,
            opponentNick: response.participants[0].nick,
            lastMessageID: response.lastChat?.chatId ?? "",
            lastMessageContent: response.lastChat?.content ?? "",
            lastMessageCreatedAt: response.lastChat?.createdAt ?? "",
            lastMessageSenderID: response.lastChat?.sender.userId ?? "",
            lastMessageFiles: fileList
        )
    }
}
