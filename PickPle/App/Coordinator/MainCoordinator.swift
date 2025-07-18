//
//  MainCoordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

// MARK: - MainCoordinator
final class MainCoordinator: ObservableObject {
    @Published var homeCoordinator = HomeCoordinator()
    @Published var historyCoordinator = OrderCoordinator()
    @Published var communityCoordinator = CommunityCoordinator()
    @Published var chatCoordinator = ChatCoordinator()
    @Published var profileCoordinator = ProfileCoordinator()
    @Published var selectedTab: TabItem = .home

    var onLogout: (() -> Void)?

    func setup() {
        setupTabCoordinators()
    }

    private func setupTabCoordinators() {
        let coordinators: [any TabCoordinator] = [
            homeCoordinator,
            historyCoordinator,
            communityCoordinator,
            chatCoordinator,
            profileCoordinator
        ]

        coordinators.forEach { coordinator in
            coordinator.onLogout = { [weak self] in
                self?.onLogout?()
            }
        }
    }

    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }
}

struct MainCoordinatorView: View {
    @EnvironmentObject var mainCoordinator: MainCoordinator
    @EnvironmentObject var appCoordinator: AppCoordinator // diContainer 접근용

    var body: some View {
        TabView(selection: $mainCoordinator.selectedTab) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                buildTab(tab)
                    .tabItem {
                        Image(mainCoordinator.selectedTab == tab ? tab.selectedIcon : tab.icon)
                    }
                    .badge(tab == .chat ? appCoordinator.totalUnreadCount : 0)
            }
        }
        .tint(.blackSprout)
        .onAppear {
            // ✅ 탭뷰가 나타날 때 초기 안읽은 메시지 개수 로드
            appCoordinator.updateTotalUnreadCount()

            // ✅ TabBar 배경색 설정
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = UIColor(Color.gray15)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    @ViewBuilder
    func buildTab(_ tab: TabItem) -> some View {
        switch tab {
        case .home:
            HomeCoordinatorView()
                .environmentObject(mainCoordinator.homeCoordinator)
        case .order:
            OrderCoordinatorView()
                .environmentObject(mainCoordinator.historyCoordinator)
        case .community:
            CommunityCoordinatorView()
                .environmentObject(mainCoordinator.communityCoordinator)
        case .chat:
            ChatCoordinatorView()
                .environmentObject(mainCoordinator.chatCoordinator)
        case .profile:
            ProfileCoordinatorView()
                .environmentObject(mainCoordinator.profileCoordinator)
        }
    }
}
