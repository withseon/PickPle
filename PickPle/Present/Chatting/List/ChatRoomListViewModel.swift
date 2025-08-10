//
//  ChatRoomListViewModel.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import Foundation
import Combine

final class ChatRoomListViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    private let chatRepository: ChatRepository
    private let realmRepository: RealmRepository

    init(chatRepository: ChatRepository, realmRepository: RealmRepository) {
        self.chatRepository = chatRepository
        self.realmRepository = realmRepository
        super.init()
        transform()
        setupNotificationObserver()
    }
}

// MARK: - Input/Output
extension ChatRoomListViewModel {
    struct Input {
        let fetchChatRoomList = PassthroughSubject<Void, Never>()
        let markAsRead = PassthroughSubject<String, Never>()
        let refreshUnreadCounts = PassthroughSubject<Void, Never>()
    }

    struct Output {
        var chatRoomList = [ChatRoom]()
    }

    func transform() {
        input.fetchChatRoomList
            .sink(with: self) { owner, _ in
                owner.fetchChatRoomList()
            }
            .store(in: &cancellables)
        
        input.markAsRead
            .sink(with: self) { owner, roomId in
                owner.markChatRoomAsRead(roomId: roomId)
            }
            .store(in: &cancellables)
        
        input.refreshUnreadCounts
            .sink(with: self) { owner, _ in
                owner.refreshUnreadCountsFromRealm()
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObserver() {
        // 푸시 알림으로 인한 안 읽은 메시지 개수 업데이트 감지
        NotificationCenter.default.publisher(for: NSNotification.Name("UpdateUnreadCount"))
            .sink { [weak self] notification in
                guard let self,
                      let userInfo = notification.userInfo,
                      let roomId = userInfo["roomId"] as? String else { return }
                
                print("📊 안읽은 메시지 개수 업데이트 알림 수신: \(roomId)")
                
                // 1. 서버에서 최신 채팅방 목록 가져오기
                self.fetchChatRoomListFromServer()
                
                // 2. UI 업데이트를 위해 Realm에서 최신 데이터 로드
                self.refreshUnreadCountsFromRealm()
            }
            .store(in: &cancellables)
    }
    
    private func fetchChatRoomList() {
        // 먼저 Realm에서 기존 데이터 로드 (안읽은 메시지 개수 포함)
        loadChatRoomListFromRealm()
        
        // 서버에서 최신 채팅방 목록 가져오기
        let publish = chatRepository.chatRoomList()
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    // 기존 안읽은 메시지 개수를 먼저 백업
                    var unreadCountBackup: [String: Int] = [:]
                    let existingChatRooms = owner.realmRepository.readTable(type: ChatRoomTable.self)
                    for chatRoom in existingChatRooms {
                        unreadCountBackup[chatRoom.roomID] = chatRoom.unreadCount
                    }
                    
                    // 새로운 데이터 저장
                    success.data.forEach { chatRoomResponse in
                        let newChatRoomTable = ChatRoomTable.from(chatRoomResponse)
                        // 기존 안읽은 개수가 있다면 복원
                        if let existingUnreadCount = unreadCountBackup[chatRoomResponse.roomId] {
                            newChatRoomTable.unreadCount = existingUnreadCount
                        }
                        owner.realmRepository.addItem(type: ChatRoomTable.self, item: newChatRoomTable)
                    }
                    
                    // UI 업데이트
                    DispatchQueue.main.async {
                        owner.loadChatRoomListFromRealm()
                    }
                case .failure(let error):
                    print("채팅방 목록 로드 실패: \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadChatRoomListFromRealm() {
        let chatRoomTables = realmRepository.readTable(type: ChatRoomTable.self)
        
        // 최신 메시지 순으로 정렬 (lastMessageCreatedAt 기준 내림차순)
        output.chatRoomList = chatRoomTables
            .sorted { $0.lastMessageCreatedAt > $1.lastMessageCreatedAt }
            .map { $0.asChatRoom }
        
        print("📊 채팅방 목록 로드 완료: \(output.chatRoomList.count)개, 안읽은 메시지가 있는 채팅방: \(output.chatRoomList.filter { $0.unreadCount > 0 }.count)개")
    }
    
    // ✅ 서버에서 채팅방 목록만 가져오는 별도 메서드 (기존과 동일)
    private func fetchChatRoomListFromServer() {
        print("📊 서버에서 채팅방 목록 새로고침 시작")
        
        let publish = chatRepository.chatRoomList()
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    print("📊 서버에서 채팅방 목록 새로고침 성공: \(success.data.count)개")
                    
                    // 기존 안읽은 메시지 개수를 먼저 백업
                    var unreadCountBackup: [String: Int] = [:]
                    let existingChatRooms = owner.realmRepository.readTable(type: ChatRoomTable.self)
                    for chatRoom in existingChatRooms {
                        unreadCountBackup[chatRoom.roomID] = chatRoom.unreadCount
                    }
                    
                    // 새로운 데이터 저장
                    success.data.forEach { chatRoomResponse in
                        let newChatRoomTable = ChatRoomTable.from(chatRoomResponse)
                        // 기존 안읽은 개수가 있다면 복원
                        if let existingUnreadCount = unreadCountBackup[chatRoomResponse.roomId] {
                            newChatRoomTable.unreadCount = existingUnreadCount
                        }
                        owner.realmRepository.addItem(type: ChatRoomTable.self, item: newChatRoomTable)
                    }
                    
                    // UI 업데이트
                    DispatchQueue.main.async {
                        owner.loadChatRoomListFromRealm()
                        print("📊 채팅방 목록 UI 업데이트 완료")
                    }
                    
                case .failure(let error):
                    print("📊 서버에서 채팅방 목록 새로고침 실패: \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshUnreadCountsFromRealm() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            loadChatRoomListFromRealm()
        }
    }
    
    private func markChatRoomAsRead(roomId: String) {
        print("📖 채팅방 읽음 처리: \(roomId)")
        
        // 채팅방의 안 읽은 메시지 수 초기화
        realmRepository.resetUnreadCount(roomId: roomId)
        
        // 배지 업데이트를 요청하는 알림 전송 (기존 방식 유지)
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateAppBadge"),
            object: nil,
            userInfo: nil
        )
        
        // UI 새로고침
        refreshUnreadCountsFromRealm()
    }
    
}

// MARK: - Action
extension ChatRoomListViewModel {
    enum Action {
        case fetchChatList
        case markAsRead(_ roomId: String)
        case refreshUnreadCounts
    }

    func action(_ action: Action) {
        switch action {
        case .fetchChatList:
            input.fetchChatRoomList
                .send(())
        case .markAsRead(let roomId):
            input.markAsRead
                .send(roomId)
        case .refreshUnreadCounts:
            input.refreshUnreadCounts
                .send(())
        }
    }
}
