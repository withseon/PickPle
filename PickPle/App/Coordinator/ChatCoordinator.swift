//
//  ChatCoordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

enum ChatRoute: Hashable {
    case chatRoom(roomId: String, nick: String)
}

// MARK: - ChatCoordinator
final class ChatCoordinator: TabCoordinator {
    @Published private(set) var path = NavigationPath()
    var onLogout: (() -> Void)?

    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { newPath in self.path = newPath }
    }

    func push(_ route: ChatRoute) {
        path.append(route)
    }

    func pushReplacingCurrent(_ route: ChatRoute) {
        // 현재 스택을 모두 지우고 새로운 채팅방으로 이동
        if case .chatRoom(let newRoomId, _) = route {
            print("🔵 [ChatCoordinator] 채팅방 교체: \(newRoomId)")
            path = NavigationPath()
            path.append(route)
        }
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}

struct ChatCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var chattingCoordinator: ChatCoordinator

    var body: some View {
        NavigationStack(path: chattingCoordinator.getPath) {
            ChatRoomListView(viewModel: ChatRoomListViewModel(chatRepository: appCoordinator.diContainer.chatRepository, realmRepository: appCoordinator.diContainer.realmRepository))
                .navigationDestination(for: ChatRoute.self) { route in
                    build(route)
                }
                .onAppear {
                    print("📱 ChatCoordinatorView onAppear")
                    // 채팅 목록 화면에서는 채팅방 상태 초기화
                    ChatStateManager.shared.exitChatRoom()
                }
        }
    }

    @ViewBuilder
    func build(_ route: ChatRoute) -> some View {
        switch route {
        case .chatRoom(let roomId, let nick):
            ChatRoomView(
                viewModel: ChatRoomViewModel(
                    chatRepository: appCoordinator.diContainer.chatRepository,
                    realmRepository: appCoordinator.diContainer.realmRepository,
                    roomId: roomId
                ),
                nick: nick
            )
            .id(roomId)
            .addBackButton {
                chattingCoordinator.pop()
            }
        }
    }
}
