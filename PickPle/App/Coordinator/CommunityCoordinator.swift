//
//  CommunityCoordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

enum CommunityRoute: Hashable {
    case profile(_ userId: String, nickname: String?, profileImage: String?)
    case postDetail(_ postId: String)
    case createPost
    case editPost(_ postDetail: PostDetail)
}

// MARK: - CommunityCoordinator
final class CommunityCoordinator: TabCoordinator {
    @Published private(set) var path = NavigationPath()
    var onLogout: (() -> Void)?

    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { newPath in self.path = newPath }
    }

    func push(_ item: CommunityRoute) {
        path.append(item)
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

struct CommunityCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var communityCoordinator: CommunityCoordinator

    var body: some View {
        NavigationStack(path: communityCoordinator.getPath) {
            CommunityView(viewModel: CommunityViewModel(postRepository: appCoordinator.diContainer.postRepository))
                .environmentObject(communityCoordinator)
                .navigationDestination(for: CommunityRoute.self) { route in
                    build(route)
                }
                .onAppear {
                    // 채팅방 상태 초기화
                    ChatStateManager.shared.exitChatRoom()
                }
        }
    }

    @ViewBuilder
    func build(_ route: CommunityRoute) -> some View {
        switch route {
        case .profile(let userId, let nickname, let profileImage):
            UserProfileView(viewModel: UserProfileViewModel(userId: userId, nickname: nickname, profileImage: profileImage, userRepository: appCoordinator.diContainer.userRepository, postRepository: appCoordinator.diContainer.postRepository))
            .addBackButton {
                communityCoordinator.pop()
            }
        case .postDetail(let postId):
            PostDetailView(viewModel: PostDetailViewModel(postId: postId, postRepository: appCoordinator.diContainer.postRepository))
            .addBackButton {
                communityCoordinator.pop()
            }
        case .createPost:
            CreatePostView(viewModel: CreatePostViewModel(postRepository: appCoordinator.diContainer.postRepository))
            .addBackButton {
                communityCoordinator.pop()
            }
        case .editPost(let postDetail):
            CreatePostView(
                editingPost: postDetail,
                viewModel: CreatePostViewModel(postRepository: appCoordinator.diContainer.postRepository),
                onPostUpdated: {
                    // 수정 완료 후 이전 화면으로 돌아가면서 데이터 새로고침을 위한 알림 전송
                    NotificationCenter.default.post(name: Notification.Name("PostUpdated"), object: postDetail.postId)
                    communityCoordinator.pop()
                }
            )
            .addBackButton {
                communityCoordinator.pop()
            }
        }
    }
}
