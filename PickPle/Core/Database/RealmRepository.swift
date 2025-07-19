//
//  RealmRepository.swift
//  PickPle
//
//  Created by 정인선 on 7/21/25.
//

import Foundation
import RealmSwift

protocol RealmRepository {
    func getFileURL()
    func readTable<T: Object>(type: T.Type) -> Results<T>
    func addItem<T: Object>(type: T.Type, item: T)
    func deleteItem<T: Object>(type: T.Type, item: T)
}

final class DefaultRealmRepository: RealmRepository {
    private var realm: Realm { try! Realm() }
    
    func getFileURL() {
        guard let fileURL = realm.configuration.fileURL else { return }
        print("📁", fileURL)
    }
        
    func readTable<T: Object>(type: T.Type) -> Results<T> {
        return realm.objects(type)
    }
    
    func addItem<T: Object>(type: T.Type, item: T) {
        do {
            try realm.write {
                realm.add(item, update: .modified)
                print("realm add")
            }
        } catch {
            print(error)
        }
    }
    
    func deleteItem<T: Object>(type: T.Type, item: T) {
        do {
            try realm.write {
                realm.delete(item)
                print("realm delete")
            }
        } catch {
            print(error)
        }
    }
}

extension RealmRepository {
    func updateItem<T: Object>(type: T.Type, primaryKey: Any, update: @escaping (T) -> Void) {
        do {
            let realm = try Realm()
            if let object = realm.object(ofType: type, forPrimaryKey: primaryKey) {
                try realm.write {
                    update(object)
                }
            }
        } catch {
            print("Realm 업데이트 실패: \(error)")
        }
    }
    
    // 채팅방의 안읽은 메시지 개수 증가
    func incrementUnreadCount(roomId: String) {
        updateItem(type: ChatRoomTable.self, primaryKey: roomId) { chatRoom in
            chatRoom.unreadCount += 1
        }
    }
    
    // 채팅방의 안읽은 메시지 개수 초기화
    func resetUnreadCount(roomId: String) {
        updateItem(type: ChatRoomTable.self, primaryKey: roomId) { chatRoom in
            chatRoom.unreadCount = 0
        }
    }
    
    // 특정 채팅방의 안읽은 메시지 개수 조회
    func getUnreadCount(roomId: String) -> Int {
        do {
            let realm = try Realm()
            if let chatRoom = realm.object(ofType: ChatRoomTable.self, forPrimaryKey: roomId) {
                return chatRoom.unreadCount
            }
        } catch {
            print("Realm 조회 실패: \(error)")
        }
        return 0
    }
    
    // 모든 채팅방의 안읽은 메시지 개수 조회
    func getAllUnreadCount() -> Int {
        do {
            let realm = try Realm()
            let allChatRooms = realm.objects(ChatRoomTable.self)
            return allChatRooms.reduce(0) { $0 + $1.unreadCount }
        } catch {
            print("Realm 조회 실패: \(error)")
        }
        return 0
    }
    
    // MARK: - 채팅 메시지 페이지네이션
    
    // 채팅 메시지 페이지네이션 조회 (최신 메시지부터)
    func getChatMessages(
        chatRoomId: String, 
        limit: Int = 20,
        before: String? = nil
    ) -> (messages: [ChatMessage], oldestMessageUTC: String?) {
        do {
            let realm = try Realm()
            var query = realm.objects(ChatMessageTable.self)
                .filter("roomId == %@", chatRoomId)
            
            // before 파라미터가 있으면 해당 시간 이전 메시지만 (UTC 문자열 비교)
            if let beforeUTC = before {
                query = query.filter("createdAt < %@", beforeUTC)
            }
            
            let results = query
                .sorted(byKeyPath: "createdAt", ascending: false)  // 최신순
                .prefix(limit)
            
            let messages = Array(results.map { $0.asChatMessage })
            
            // 가장 오래된 메시지의 UTC 문자열 추출
            let oldestMessageUTC = results.last?.createdAtUTC
            
            return (messages: messages, oldestMessageUTC: oldestMessageUTC)
        } catch {
            print("❌ [RealmRepository] 채팅 메시지 페이지네이션 조회 실패: \(error)")
            return (messages: [], oldestMessageUTC: nil)
        }
    }
    
    // 특정 시간 이후의 새 메시지 조회 (실시간 업데이트용)
    func getNewChatMessages(
        chatRoomId: String,
        after: Date
    ) -> [ChatMessage] {
        do {
            let realm = try Realm()
            let results = realm.objects(ChatMessageTable.self)
                .filter("roomId == %@ AND createdAt > %@", chatRoomId, after)
                .sorted(byKeyPath: "createdAt", ascending: true)  // 오래된 순
            
            return results.map { $0.asChatMessage }
        } catch {
            print("❌ [RealmRepository] 새 채팅 메시지 조회 실패: \(error)")
            return []
        }
    }
    
    // 채팅방의 총 메시지 개수 조회
    func getChatMessageCount(chatRoomId: String) -> Int {
        do {
            let realm = try Realm()
            return realm.objects(ChatMessageTable.self)
                .filter("roomId == %@", chatRoomId)
                .count
        } catch {
            print("❌ [RealmRepository] 채팅 메시지 개수 조회 실패: \(error)")
            return 0
        }
    }
}
