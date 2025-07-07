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

    init(chatRepository: ChatRepository) {
        self.chatRepository = chatRepository
        super.init()
        transform()
    }
}

// MARK: - Input/Output
extension ChatRoomListViewModel {
    struct Input {
        let fetchChatRoomList = PassthroughSubject<Void, Never>()
    }

    struct Output {
        var chatRoomList = [ChatRoomThumbnail]()
    }

    func transform() {
        input.fetchChatRoomList
            .sink(with: self) { owner, _ in
                owner.fetchChatRoomList()
            }
            .store(in: &cancellables)
    }
    
    private func fetchChatRoomList() {
        let publish = chatRepository.chatRoomList()
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    print(success.data)
                    owner.output.chatRoomList = success.data.map { $0.asChatRoomThumbnail }
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Action
extension ChatRoomListViewModel {
    enum Action {
        case fetchChatList
    }

    func action(_ action: Action) {
        switch action {
        case .fetchChatList:
            input.fetchChatRoomList
                .send(())
        }
    }
}

