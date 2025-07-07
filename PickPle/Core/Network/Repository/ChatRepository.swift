//
//  ChatRepository.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import Foundation
import Combine

protocol ChatRepository {
    func chatRoom(_ userId: String) -> AnyPublisher<Result<ChatRoomResponse, NetworkError>, Never>
    func chatRoomList() -> AnyPublisher<Result<ChatRoomListResponse, NetworkError>, Never>
    func sendChat(roomId: String, param: ChatParam) -> AnyPublisher<Result<ChatResponse, NetworkError>, Never>
    func chatMessages(roomId: String, next: String?) -> AnyPublisher<Result<ChatListResponse, NetworkError>, Never>
}

final class DefaultChatRepository: ChatRepository {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func chatRoom(_ userId: String) -> AnyPublisher<Result<ChatRoomResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let dto = ChatRoomRequest(opponentId: userId)
                    let chatRoom = try await networkManager.request(
                        target: ChatRouter.chatRoom(dto),
                        responseType: ChatRoomResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(chatRoom)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func chatRoomList() -> AnyPublisher<Result<ChatRoomListResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let chatRoomList = try await networkManager.request(
                        target: ChatRouter.chatRoomList,
                        responseType: ChatRoomListResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(chatRoomList)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func sendChat(roomId: String, param: ChatParam) -> AnyPublisher<Result<ChatResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let dto = SendChatRequest(content: param.content, file: param.files)
                    let chatMessage = try await networkManager.request(
                        target: ChatRouter.sendChat(roomId: roomId, request: dto),
                        responseType: ChatResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(chatMessage)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func chatMessages(roomId: String, next: String?) -> AnyPublisher<Result<ChatListResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let dto = ChatMessageRequest(next: next)
                    let chatMessages = try await networkManager.request(
                        target: ChatRouter.chatMessage(roomId: roomId, request: dto),
                        responseType: ChatListResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(chatMessages)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
