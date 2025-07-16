//
//  ChatRoomThumbnail.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import Foundation

struct ChatRoom {
    let roomId: String
    let updatedAt: String
    let lastChat: String
    let userId: String
    let nick: String
    let profileImage: String?
    var unreadCount: Int = 0 // 안 읽은 메시지 개수
}
