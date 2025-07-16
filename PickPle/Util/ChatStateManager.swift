//
//  ChatStateManager.swift
//  PickPle
//
//  Created by 정인선 on 7/31/25.
//

import Foundation

final class ChatStateManager: ObservableObject {
    static let shared = ChatStateManager()
    
    @Published var currentChatRoomId: String? = nil
    @Published var isInChatRoom: Bool = false
    
    private init() {}
    
    // 채팅방 진입
    func enterChatRoom(roomId: String) {
        print("🟢 채팅방 진입: \(roomId)")
        currentChatRoomId = roomId
        isInChatRoom = true
    }
    
    // 채팅방 나가기
    func exitChatRoom() {
        if let roomId = currentChatRoomId {
            print("🔴 채팅방 나가기: \(roomId)")
        }
        currentChatRoomId = nil
        isInChatRoom = false
    }
    
    // 현재 채팅방인지 확인
    func isCurrentChatRoom(_ roomId: String) -> Bool {
        let isCurrent = isInChatRoom && currentChatRoomId == roomId
        print("📱 현재 채팅방 확인: \(roomId) -> \(isCurrent ? "같음(알림차단)" : "다름(알림허용)")")
        return isCurrent
    }
}
