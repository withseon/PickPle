//
//  ProfileCoordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

enum ProfileRoute: Hashable {
    case postDetail(_ postId: String)
}

// MARK: - ProfileCoordinator
final class ProfileCoordinator: TabCoordinator {
    @Published private(set) var path = NavigationPath()
    var onLogout: (() -> Void)?

    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { newPath in self.path = newPath }
    }

    func push(_ route: ProfileRoute) {
        path.append(route)
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

struct ProfileCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var profileCoordinator: ProfileCoordinator

    var body: some View {
        NavigationStack(path: profileCoordinator.getPath) {
            UserProfileView(
                viewModel: UserProfileViewModel(
                    userRepository: appCoordinator.diContainer.userRepository,
                    postRepository: appCoordinator.diContainer.postRepository)
            )
            .environmentObject(profileCoordinator)
            .navigationDestination(for: ProfileRoute.self) { route in
                build(route)
            }
        }
        .onAppear {
            // 채팅방 상태 초기화
            ChatStateManager.shared.exitChatRoom()
        }
    }

    @ViewBuilder
    func build(_ route: ProfileRoute) -> some View {
        switch route {
        case .postDetail(let postId):
            PostDetailView(viewModel: PostDetailViewModel(postId: postId, postRepository: appCoordinator.diContainer.postRepository))
            .addBackButton {
                profileCoordinator.pop()
            }
        }
    }
}
