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
    @Persisted var opponentProfile: String?

    @Persisted var lastMessageID: String
    @Persisted var lastMessageContent: String
    @Persisted var lastMessageCreatedAt: String
    @Persisted var lastMessageSenderID: String
    @Persisted var lastMessageFiles: List<String>
    
    // 클라이언트에서 관리하는 안 읽은 메시지 개수
    @Persisted var unreadCount: Int = 0
    
    convenience init(
        roomID: String,
        createdAt: String,
        updatedAt: String? = nil,
        opponentID: String,
        opponentNick: String,
        opponentProfile: String? = nil,
        lastMessageID: String,
        lastMessageContent: String,
        lastMessageCreatedAt: String,
        lastMessageSenderID: String,
        lastMessageFiles: List<String>,
        unreadCount: Int = 0
    ) {
        self.init()
        self.roomID = roomID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.opponentID = opponentID
        self.opponentNick = opponentNick
        self.opponentProfile = opponentProfile
        self.lastMessageID = lastMessageID
        self.lastMessageContent = lastMessageContent
        self.lastMessageCreatedAt = lastMessageCreatedAt
        self.lastMessageSenderID = lastMessageSenderID
        self.lastMessageFiles = lastMessageFiles
        self.unreadCount = unreadCount
    }
}

extension ChatRoomTable {
    static func from(_ response: ChatRoomResponse) -> ChatRoomTable {
        var participants = response.participants
        if response.participants.count > 1 {
            participants = participants.filter { $0.userId != UserDefaultsManager.userId }
        }
        
        let fileList = List<String>()
        fileList.append(objectsIn: response.lastChat?.files ?? [])
        
        return ChatRoomTable(
            roomID: response.roomId,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt,
            opponentID: participants[0].userId,
            opponentNick: participants[0].nick,
            opponentProfile: participants[0].profileImage,
            lastMessageID: response.lastChat?.chatId ?? "",
            lastMessageContent: response.lastChat?.content ?? "",
            lastMessageCreatedAt: response.lastChat?.createdAt ?? "",
            lastMessageSenderID: response.lastChat?.sender.userId ?? "",
            lastMessageFiles: fileList,
            unreadCount: 0 // 서버에서 지원하지 않으므로 항상 0으로 초기화
        )
    }
    
    var asChatRoom: ChatRoom {
        return ChatRoom(
            roomId: roomID,
            updatedAt: FormatHelper.shared.getChatTime(from: updatedAt ?? ""),
            lastChat: lastMessageContent,
            userId: opponentID,
            nick: opponentNick,
            profileImage: opponentProfile,
            unreadCount: unreadCount
        )
    }
}
