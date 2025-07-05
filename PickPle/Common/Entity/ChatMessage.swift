//
//  ChatMessage.swift
//  PickPle
//
//  Created by 정인선 on 7/21/25.
//

import Foundation

struct ChatMessage: Hashable {
    var chatId: String
    var roomId: String
    var content: String
    var createdAt: String
    var updatedAt: String
    var sender: UserInfo
    var files: [String]
}
