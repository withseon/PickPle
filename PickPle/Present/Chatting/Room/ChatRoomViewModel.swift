//
//  ChatRoomViewModel.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import Foundation
import Combine

// 채팅 아이템 (메시지 + 날짜 구분선)
struct ChatItem {
    let message: ChatMessage
    let dateSeparator: String? // 날짜 구분선 텍스트
}

final class ChatRoomViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    private let chatRepository: ChatRepository
    private let realmRepository: RealmRepository
    private var chatParam = ChatParam.empty
    let roomId: String
    
    // MARK: - 페이지네이션 관련 프로퍼티
    private let pageSize = 20
    private var oldestLoadedMessageUTC: String?

    // MARK: - 메시지 동기화 관련 프로퍼티
    private var lastSyncTime: String?
    
    @Published var socketService = SocketService()

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
        let loadOlderMessages = PassthroughSubject<Void, Never>()  // 이전 메시지 로드
        let sendMessage = PassthroughSubject<String, Never>()
        let sendFiles = PassthroughSubject<[SelectedFile], Never>()
        let socketConnect = PassthroughSubject<Void, Never>()
        let socketDisconnect = PassthroughSubject<Void, Never>()
        let markAsRead = PassthroughSubject<Void, Never>()
        let addSelectedFiles = PassthroughSubject<[SelectedFile], Never>()
    }

    struct Output {
        var isInitialLoading = true
        var isLoadingMore = false  // 이전 메시지 로딩 중
        var hasMoreMessages = true  // 더 로드할 메시지가 있는지
        var chatMessages = [ChatMessage]()
        var chatItems = [ChatItem]() // 날짜 구분선이 포함된 채팅 아이템들
        var selectedFiles = [SelectedFile]() // 선택된 파일들
    }

    func transform() {
        input.fetchChatMessages
            .sink(with: self) { owner, _ in
                owner.fetchChatMessages()
            }
            .store(in: &cancellables)
        
        input.loadOlderMessages
            .sink(with: self) { owner, _ in
                owner.loadOlderMessages()
            }
            .store(in: &cancellables)
        
        input.sendMessage
            .sink(with: self) { owner, message in
                owner.sendMessage(message)
            }
            .store(in: &cancellables)
        
        input.sendFiles
            .sink(with: self) { owner, files in
                owner.sendFile(files)
            }
            .store(in: &cancellables)
        
        input.socketConnect
            .sink(with: self) { owner, _ in
                owner.fetchChatMessages()
            }
            .store(in: &cancellables)
        
        input.socketDisconnect
            .sink(with: self) { owner, _ in
                owner.socketService.disconnect()
            }
            .store(in: &cancellables)
        
        input.markAsRead
            .sink(with: self) { owner, _ in
                owner.markMessagesAsRead()
            }
            .store(in: &cancellables)

        input.addSelectedFiles
            .sink(with: self) { owner, files in
                owner.addSelectedFiles(files)
            }
            .store(in: &cancellables)
    }
    
    private func fetchChatMessages() {
        // 초기 로딩 시작
        output.isInitialLoading = true
        
        // Realm에서 최신 메시지들 로드 (페이지네이션)
        let result = realmRepository.getChatMessages(
            chatRoomId: roomId,
            limit: pageSize,
            before: nil
        )
        
        // 로컬 메시지가 있으면 UI 업데이트
        if !result.messages.isEmpty {
            output.chatMessages = result.messages.reversed()
            updateChatItems()
            
            // 가장 오래된 메시지 UTC 문자열 저장
            oldestLoadedMessageUTC = result.oldestMessageUTC
            
            // 더 로드할 메시지가 있는지 확인
            output.hasMoreMessages = result.messages.count == pageSize
        }
        
        // 서버에서 새 메시지 가져오기
        let lastMessageDate = result.messages.first?.createdAtUTC
        lastSyncTime = lastMessageDate  // 동기화 시점 기록
        let publish = chatRepository.chatMessages(roomId: roomId, next: lastMessageDate)
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
                        // 새 메시지를 기존 메시지 뒤에 추가
                        owner.output.chatMessages.append(contentsOf: response.data.map { $0.asChatMessage })
                        owner.updateChatItems()
                        owner.output.isInitialLoading = false
                    }
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        owner.output.isInitialLoading = false
                    }
                }
            }
            .store(in: &cancellables)
        
        socketService.connect(roomId)
        setupSocketListener()
    }
    
    // MARK: - 이전 메시지 로드 (페이지네이션)
    private func loadOlderMessages() {
        print("🔍 [ViewModel] loadOlderMessages 메서드 호출됨!")
        print("🔍 [ViewModel] 현재 상태:")
        print("  - isLoadingMore: \(output.isLoadingMore)")
        print("  - hasMoreMessages: \(output.hasMoreMessages)")
        print("  - 현재 메시지 개수: \(output.chatMessages.count)")
        print("  - oldestLoadedMessageUTC: \(oldestLoadedMessageUTC ?? "nil")")
        
        // 이미 로딩 중이거나 더 이상 로드할 메시지가 없으면 리턴
        guard !output.isLoadingMore && output.hasMoreMessages else { 
            print("❌ [ViewModel] 이전 메시지 로드 건너뜀:")
            print("  - 로딩중: \(output.isLoadingMore)")
            print("  - 더 있음: \(output.hasMoreMessages)")
            return 
        }
        
        print("✅ [ViewModel] 페이지네이션 조건 통과! 이전 메시지 로드 시작")
        output.isLoadingMore = true
        
        print("🔍 [ViewModel] Realm 조회 파라미터:")
        print("  - chatRoomId: \(roomId)")
        print("  - limit: \(pageSize)")
        print("  - before: \(oldestLoadedMessageUTC ?? "nil")")
        
        let result = realmRepository.getChatMessages(
            chatRoomId: roomId,
            limit: pageSize,
            before: oldestLoadedMessageUTC
        )
        
        print("🔍 [ViewModel] Realm 조회 결과:")
        print("  - 조회된 메시지 개수: \(result.messages.count)")
        print("  - 새로운 oldestMessageUTC: \(result.oldestMessageUTC ?? "nil")")
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if !result.messages.isEmpty {
                print("✅ [ViewModel] 이전 메시지 \(result.messages.count)개 로드됨")
                print("📊 [ViewModel] 메시지 추가 전 총 개수: \(self.output.chatMessages.count)")
                
                // 기존 메시지 앞에 추가 (역순으로 변환하여)
                self.output.chatMessages.insert(contentsOf: result.messages.reversed(), at: 0)
                self.updateChatItems()
                
                print("📊 [ViewModel] 메시지 추가 후 총 개수: \(self.output.chatMessages.count)")
                
                // 가장 오래된 메시지 UTC 문자열 업데이트
                self.oldestLoadedMessageUTC = result.oldestMessageUTC
                print("📍 [ViewModel] oldestLoadedMessageUTC 업데이트: \(result.oldestMessageUTC ?? "nil")")
                
                // 더 로드할 메시지가 있는지 확인
                let hasMore = result.messages.count == self.pageSize
                self.output.hasMoreMessages = hasMore
                print("🔄 [ViewModel] hasMoreMessages 업데이트: \(hasMore) (받은 개수: \(result.messages.count), pageSize: \(self.pageSize))")
            } else {
                print("⚠️ [ViewModel] Realm에서 조회된 이전 메시지 없음 - hasMoreMessages = false")
                self.output.hasMoreMessages = false
            }
            
            self.output.isLoadingMore = false
            print("🏁 [ViewModel] 페이지네이션 완료")
        }
    }
    
    private func updateChatItems() {
        var items: [ChatItem] = []
        var previousDate: String? = nil
        
        for message in output.chatMessages {
            // 메시지의 실제 생성 날짜 추출 (createdAtUTC 사용)
            let messageDate = FormatHelper.shared.getDateFromUTC(message.createdAtUTC)
            
            // 이전 메시지와 날짜가 다르면 날짜 구분선 추가
            var dateSeparator: String? = nil
            if previousDate != messageDate {
                dateSeparator = FormatHelper.shared.formatDateSeparator(messageDate)
                previousDate = messageDate
            }
            
            let item = ChatItem(message: message, dateSeparator: dateSeparator)
            items.append(item)
        }
        
        output.chatItems = items
    }

    private func extractDate(from timeString: String) -> String {
        // createdAt은 이미 FormatHelper에서 처리된 시간 형태
        // 원본 UTC 시간을 다시 가져와서 날짜 부분만 추출해야 함
        // 임시로 현재 날짜를 사용하지만, 실제로는 원본 UTC 시간에서 날짜를 추출해야 함
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func formatDateSeparator(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy년 M월 d일"
        outputFormatter.locale = Locale(identifier: "ko_KR")
        
        return outputFormatter.string(from: date)
    }
    
    private func setupSocketListener() {
        socketService.onMessageReceived = { [weak self] message in
            guard let self else { return }
            handleSocketMessage(message)
        }

        // 웹소켓 연결 완료 시 백그라운드 동기화 수행
        socketService.onSocketConnected = { [weak self] in
            guard let self else { return }
            performBackgroundSync()
        }
    }
    
    private func handleSocketMessage(_ message: ChatResponse) {
        if message.sender.userId != UserDefaultsManager.userId {
            realmRepository.addItem(type: ChatMessageTable.self, item: ChatMessageTable.from(message))
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                output.chatMessages.append(message.asChatMessage)
                updateChatItems()
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
                        owner.updateChatItems()
                    }
                    owner.chatParam.files = []
                case .failure(let error):
                    print(error)
                    // TODO: - 전송 재시도 or 취소
                }
            }
            .store(in: &cancellables)
    }
    
    private func sendFile(_ files: [SelectedFile]) {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("📊 파일 전송 프로세스 시작")
        
        // 개선된 방식: 원본 확장자 유지, nil 처리 추가
        let multipartFiles = files.compactMap { $0.asMultipartFile }
        let publish = chatRepository.sendFile(roomId: roomId, files: multipartFiles)
        
        publish
            .sink(with: self) { owner, result in
                switch result {
                case .success(let response):
                    let uploadTime = CFAbsoluteTimeGetCurrent() - startTime
                    print("📊 파일 업로드 완료 - 소요시간: \(uploadTime)초")
                    
                    owner.cacheUploadedImages(files: files, serverPaths: response.files)
                    
                    let messageStartTime = CFAbsoluteTimeGetCurrent()
                    owner.chatParam.files = response.files
                    owner.sendMessage("파일을 보냈습니다.")
                    
                    let messageTime = CFAbsoluteTimeGetCurrent() - messageStartTime
                    print("📊 메시지 전송 소요시간: \(messageTime)초")
                    
                    let totalTime = CFAbsoluteTimeGetCurrent() - startTime
                    print("📊 전체 파일 전송 프로세스 완료 - 총 소요시간: \(totalTime)초")
                    
                case .failure(let error):
                    let failTime = CFAbsoluteTimeGetCurrent() - startTime
                    print("📊 파일 전송 실패 - 소요시간: \(failTime)초")
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func cacheUploadedImages(files: [SelectedFile], serverPaths: [String]) {
        for (index, file) in files.enumerated() {
            guard index < serverPaths.count,
                  file.type == .image,
                  let image = file.image else { continue }
            
            let serverPath = serverPaths[index]
            
            // 2단계 캐싱: 썸네일(300x300) + 풀사이즈(1080x1080) 동시 저장
            ImageCacheManager.shared.cacheUploadedImage(image: image, forKey: serverPath, originalData: file.data)
        }
    }
    
    private func markMessagesAsRead() {
        // 읽음 처리 API 호출 (구현 필요)
        // 채팅방 목록의 unreadCount 업데이트
        NotificationCenter.default.post(
            name: NSNotification.Name("ChatRoomRead"),
            object: nil,
            userInfo: ["roomId": roomId]
        )
    }

    // MARK: - 백그라운드 메시지 동기화
    private func performBackgroundSync() {
        // 동기화 시점이 기록되지 않았으면 실행하지 않음
        guard let syncTime = lastSyncTime else {
            print("🤫 [BackgroundSync] 동기화 시점이 없어 건너뜀")
            return
        }

        print("🤫 [BackgroundSync] 웹소켓 연결 완료 - 백그라운드 동기화 시작")
        print("🤫 [BackgroundSync] 동기화 기준 시점: \(syncTime)")

        let publish = chatRepository.chatMessages(roomId: roomId, next: syncTime)
        publish
            .sink(with: self) { owner, result in
                switch result {
                case .success(let response):
                    let newMessageCount = response.data.count

                    if newMessageCount > 0 {
                        print("🤫 [BackgroundSync] 누락 메시지 \(newMessageCount)개 발견 - Realm에 저장")

                        // 조용히 Realm에만 저장 (UI 업데이트 없음)
                        response.data.forEach { message in
                            owner.realmRepository.addItem(
                                type: ChatMessageTable.self,
                                item: ChatMessageTable.from(message)
                            )
                        }

                        print("✅ [BackgroundSync] 백그라운드 동기화 완료 - \(newMessageCount)개 메시지 저장")
                    } else {
                        print("🤫 [BackgroundSync] 누락된 메시지 없음")
                    }

                case .failure(let error):
                    print("❌ [BackgroundSync] 백그라운드 동기화 실패: \(error)")
                }
            }
            .store(in: &cancellables)
    }

}

// MARK: - File Handling
extension ChatRoomViewModel {
    func addSelectedFiles(_ files: [SelectedFile]) {
        output.selectedFiles.append(contentsOf: files)
    }

    func clearSelectedFiles() {
        output.selectedFiles.removeAll()
    }

    func removeSelectedFile(at index: Int) {
        guard index < output.selectedFiles.count else { return }
        output.selectedFiles.remove(at: index)
    }
}

// MARK: - Action
extension ChatRoomViewModel {
    enum Action {
        case fetchMessages
        case loadOlderMessages  // 이전 메시지 로드
        case sendMessage(_ message: String)
        case sendFile(_ files: [SelectedFile])
        case socketConnect
        case socketDisconnect
        case markAsRead
        case addSelectedFiles(_ files: [SelectedFile])
        case clearSelectedFiles
        case removeSelectedFile(at: Int)
    }

    func action(_ action: Action) {
        switch action {
        case .fetchMessages:
            input.fetchChatMessages
                .send(())
        case .loadOlderMessages:
            input.loadOlderMessages
                .send(())
        case .sendMessage(let message):
            input.sendMessage
                .send(message)
        case .sendFile(let files):
            input.sendFiles
                .send(files)
        case .socketConnect:
            input.socketConnect
                .send(())
        case .socketDisconnect:
            input.socketDisconnect
                .send(())
        case .markAsRead:
            input.markAsRead
                .send(())
        case .addSelectedFiles(let files):
            input.addSelectedFiles
                .send(files)
        case .clearSelectedFiles:
            clearSelectedFiles()
        case .removeSelectedFile(let index):
            removeSelectedFile(at: index)
        }
    }
}
