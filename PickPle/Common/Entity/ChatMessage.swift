//
//  ChatMessage.swift
//  PickPle
//
//  Created by 정인선 on 7/21/25.
//

import Foundation

struct ChatMessage {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: UserInfo
    let files: [String]
    let createdAtUTC: String // 원본 UTC 시간 (날짜 구분선용)
}
