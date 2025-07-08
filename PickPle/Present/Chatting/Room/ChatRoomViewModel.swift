//
//  ChatRoomViewModel.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import Foundation
import Combine

final class ChatRoomViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    private let chatRepository: ChatRepository
    private let realmRepository: RealmRepository
    private let roomId: String
    private var chatParam = ChatParam.empty
    
    @Published var socketService = DefaultSocketService()

    init(chatRepository: ChatRepository, realmRepository: RealmRepository, roomId: String) {
        self.chatRepository = chatRepository
        self.realmRepository = realmRepository
        self.roomId = roomId
        super.init()
        transform()
    }
}

// MARK: - Input/Output
extension ChatRoomViewModel {
    struct Input {
        let fetchChatMessages = PassthroughSubject<Void, Never>()
        let sendMessage = PassthroughSubject<String, Never>()
    }

    struct Output {
        var chatMessages = [ChatMessage]()
    }

    func transform() {
        input.fetchChatMessages
            .sink(with: self) { owner, _ in
                owner.fetchChatMessages()
            }
            .store(in: &cancellables)
        
        input.sendMessage
            .sink(with: self) { owner, message in
                owner.sendMessage(message)
            }
            .store(in: &cancellables)
    }
    
    private func fetchChatMessages() {
        let chatMessages = realmRepository.readTable(type: ChatMessageTable.self).filter("roomId ==[c] %@", roomId)
        output.chatMessages = chatMessages.map { $0.asChatMessage }
    
        let publish = chatRepository.chatMessages(roomId: roomId, next: chatMessages.last?.createdAt)
        publish
            .sink(with: self) { owner, result in
                switch result {
                case .success(let response):
                    owner.realmRepository.getFileURL()
                    response.data.forEach { [weak self] in
                        guard let self else { return }
                        realmRepository.addItem(type: ChatMessageTable.self, item: ChatMessageTable.from($0))
                    }
                    DispatchQueue.main.async {
                        owner.output.chatMessages.append(contentsOf: response.data.map { $0.asChatMessage })
                    }
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
        
        socketService.connect(roomId)
        setupSocketListener()
    }
    
    private func setupSocketListener() {
        socketService.onMessageReceived = { [weak self] message in
            self?.handleSocketMessage(message)
        }
    }
    
    private func handleSocketMessage(_ message: ChatResponse) {
        if message.sender.userId != UserDefaultsManager.userId {
            realmRepository.addItem(type: ChatMessageTable.self, item: ChatMessageTable.from(message))
        
            DispatchQueue.main.async {
                self.output.chatMessages.append(message.asChatMessage)
            }
        }
    }
    
    private func sendMessage(_ message: String) {
        chatParam.content = message
        let publish = chatRepository.sendChat(roomId: roomId, param: chatParam)
        publish
            .sink(with: self) { owner, result in
                switch result {
                case .success(let response):
                    owner.realmRepository.addItem(type: ChatMessageTable.self, item: ChatMessageTable.from(response))
                    DispatchQueue.main.async {
                        owner.output.chatMessages.append(response.asChatMessage)
                    }
                case .failure(let error):
                    print(error)
                    // TODO: - 전송 재시도 or 취소
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Action
extension ChatRoomViewModel {
    enum Action {
        case fetchMessages
        case sendMessage(_ message: String)
    }

    func action(_ action: Action) {
        switch action {
        case .fetchMessages:
            input.fetchChatMessages
                .send(())
        case .sendMessage(let message):
            input.sendMessage
                .send(message)
        }
    }
}
