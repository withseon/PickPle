//
//  SocketService.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import SwiftUI
import SocketIO

protocol SocketService: ObservableObject {
    func connect(_ roomId: String)
    func disconnect()
}

final class DefaultSocketService: SocketService {
    private var socket: SocketIOClient?
    private var manager: SocketManager?
    private var accessToken = ""
    
    @Published var messages = [ChatResponse]()
    @Published var isConnected = false
    var onMessageReceived: ((ChatResponse) -> Void)?
    
    func connect(_ roomId: String) {
        disconnect()
        
        SecureTokenManager.shared.retrieveAndDecryptToken(forKey: SecureKey.ACCESS_TOKEN) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let success):
                accessToken = success
                setupSocketConnection(roomId)
            case .failure(let failure):
                print(failure)
            }
        }
    }
    
    private func setupSocketConnection(_ roomId: String) {
        let socketURL = "\(APIURL.SOCKET)\(roomId)"
        guard let url = URL(string: socketURL) else {
            print("❌ DefaultSocketService: 잘못된 소켓 URL - \(socketURL)")
            return
        }
        
        manager = SocketManager(
            socketURL: url,
            config: [
                .log(true),
                .compress,
                .reconnects(true), // 자동 재연결 활성화
                .reconnectAttempts(5), // 재연결 시도 횟수
                .reconnectWait(1), // 재연결 대기 시간
                .extraHeaders([
                    "Authorization": accessToken,
                    "SeSACKey": APIKEY.PICKUP
                ])
            ]
        )
        
        socket = manager?.socket(forNamespace: "/chats-\(roomId)")
        setupSocketEvents()
        socket?.connect()
    }
    
    private func setupSocketEvents() {
        guard let socket else { return }
        
        // 연결 성공
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            print("🟢 DefaultSocketService: Socket connected")
            DispatchQueue.main.async {
                self?.isConnected = true
            }
        }
        
        // 연결 해제
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("🔴 DefaultSocketService: Socket disconnected")
            DispatchQueue.main.async {
                self?.isConnected = false
            }
        }
        
        // 연결 에러
        socket.on(clientEvent: .error) { [weak self] data, ack in
            print("❌ DefaultSocketService: Connection error - \(data)")
            DispatchQueue.main.async {
                self?.isConnected = false
            }
        }
        
        // 재연결 시도
        socket.on(clientEvent: .reconnectAttempt) { data, ack in
            print("🔄 DefaultSocketService: Reconnecting...")
        }

        socket.on("chat") { dataArray, ack in
            guard let data = dataArray.first else {
                print("❌ DefaultSocketService: dataArray가 비어 있음")
                return
            }
            
            do {
                var jsonData: Data?
                
                // Dictionary인 경우 (SocketIO가 자동 파싱한 경우)
                if let dictionary = data as? [String: Any] {
                    print("✅ Dictionary로 받은 데이터를 JSON으로 변환")
                    jsonData = try JSONSerialization.data(withJSONObject: dictionary)
                }
                else {
                    print("❌ 지원하지 않는 데이터 타입: \(type(of: data))")
                    return
                }
                
                if let jsonData = jsonData {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let chatResponse = try decoder.decode(ChatResponse.self, from: jsonData)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        // 중복 메시지 방지
                        if !messages.contains(where: { $0.chatId == chatResponse.chatId }) {
                            messages.append(chatResponse)
                        }
                    }
                    
                    self.onMessageReceived?(chatResponse)
                }
            } catch {
                print("❌ DefaultSocketService: JSON 파싱 실패: \(error)")
            }
        }
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        
        DispatchQueue.main.async {
            self.messages = []
            self.isConnected = false
        }
    }
    
    deinit {
        disconnect()
    }
}
