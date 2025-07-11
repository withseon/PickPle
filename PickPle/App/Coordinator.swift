//
//  Coordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

enum TabItem: CaseIterable {
    case home
    case order
    case community
    case chat
    case profile
    
    var icon: String {
        switch self {
        case .home:
            return "home"
        case .order:
            return "order"
        case .community:
            return "community"
        case .chat:
            return "chatting"
        case .profile:
            return "profile"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home:
            return "home.fill"
        case .order:
            return "order.fill"
        case .community:
            return "community.fill"
        case .chat:
            return "chatting.fill"
        case .profile:
            return "profile.fill"
        }
    }
}

enum AppRoute: Hashable {
    case signIn
    case main
}

enum AuthRoute: Hashable {
    case signup
}

enum HomeRoute: Hashable {
    case storeDetail(_ storeId: String)
}

enum OrderRoute: Hashable {
    
}

enum CommunityRoute: Hashable {
    case profile(_ userId: String)
}

enum ChatRoute: Hashable {
    case chatRoom(roomId: String, nick: String)
}

enum ProfileRoute: Hashable {
    
}

enum SheetItem: Identifiable {
    var id: UUID { UUID() }
    case map(_ completion: (() -> Void)?)
}

protocol CoordinatorProtocol: ObservableObject {
    associatedtype Route: Hashable
    associatedtype Sheet: Identifiable
    
    var path: NavigationPath { get }
    var sheet: Sheet? { get }
    
    func push(_ route: Route)
    func pop()
    func popToRoot()
    func presentSheet(_ sheet: Sheet)
    func dismissSheet()
}

// MARK: - AppCoordinator
final class AppCoordinator: CoordinatorProtocol {
    typealias Route = AppRoute
    typealias Sheet = Never
    
    @Published private(set) var path = NavigationPath()
    @Published private(set) var diContainer = DIContainer()
    @Published private(set) var sheet: Never? = nil
    @Published private(set) var current: AppRoute = .signIn
    
    // 하위 코디네이터
    @Published var authCoordinator = AuthCoordinator()
    @Published var mainCoordinator = MainCoordinator()
    
    init() {
        setup()
    }
    
    private func setup() {
        authCoordinator.onLogin = { [weak self] in
            guard let self else { return }
            current = .main
            print("로그인 성공")
        }
        
        mainCoordinator.onLogout = { [weak self] in
            guard let self else { return }
            current = .signIn
            print("로그아웃 성공")
        }
    }
    
    func push(_ route: AppRoute) {
        current = route
    }
    
    func pop() { }
    func popToRoot() { }
    func presentSheet(_ sheet: Never) { }
    func dismissSheet() { }
}

extension AppCoordinator {
    @ViewBuilder
    func build(_ route: AppRoute) -> some View {
        switch route {
        case .signIn:
            AuthCoordinatorView()
                .environmentObject(authCoordinator)
        case .main:
            MainCoordinatorView()
                .environmentObject(mainCoordinator)
        }
    }
    
    @ViewBuilder
    var currentView: some View {
        build(current)
            .transition(.slide)
    }
}

// MARK: - AppCoordinatorView
struct AppCoordinatorView: View {
    @StateObject var coordinator = AppCoordinator()
    
    var body: some View {
        coordinator.currentView
            .environmentObject(coordinator)
            .task {
                do {
                    let _ = try await coordinator.diContainer.userRepository.profile()
                    coordinator.authCoordinator.succeedLogin()
                } catch {
                    print("자동로그인 실패")
                }
            }
    }
}

// MARK: - Auth Coordinator
final class AuthCoordinator: CoordinatorProtocol {
    typealias Route = AuthRoute
    typealias Sheet = Never
    
    @Published var path = NavigationPath()
    @Published private(set) var sheet: Never? = nil
    var onLogin: (() -> Void)?
    
    func succeedLogin() {
        path = NavigationPath()
        onLogin?()
    }
    
    func push(_ route: AuthRoute) {
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
    
    func presentSheet(_ sheet: Never) { }
    func dismissSheet() { }
}

struct AuthCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        VStack {
            SignInView(viewModel: SignInViewModel(userRepository: appCoordinator.diContainer.userRepository))
        }
    }
}

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
        homeCoordinator.onLogout = { [weak self] in
            self?.onLogout?()
        }
        historyCoordinator.onLogout = { [weak self] in
            self?.onLogout?()
        }
        communityCoordinator.onLogout = { [weak self] in
            self?.onLogout?()
        }
        profileCoordinator.onLogout = { [weak self] in
            self?.onLogout?()
        }
    }
    
    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }
}

struct MainCoordinatorView: View {
    @EnvironmentObject var mainCoordinator: MainCoordinator
    
    var body: some View {
        TabView(selection: $mainCoordinator.selectedTab) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                buildTab(tab)
                    .tabItem {
                        Image(mainCoordinator.selectedTab == tab ? tab.selectedIcon : tab.icon)
                    }
            }
        }
        .tint(.blackSprout)
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

// MARK: - Coordinator Protocols
protocol TabCoordinator: ObservableObject {
    var path: NavigationPath { get }
    func popToRoot()
    func pop()
}

// MARK: - HomeCoordinator
final class HomeCoordinator: TabCoordinator {
    @Published private(set) var path = NavigationPath()
    var onLogout: (() -> Void)?
    
    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { _ in }
    }
    
    func requestLogout() {
        path = NavigationPath()
        onLogout?()
    }
    
    func push(_ item: HomeRoute) {
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

struct HomeCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var homeCoordinator: HomeCoordinator
    
    var body: some View {
        NavigationStack(path: homeCoordinator.getPath) {
            MainView(viewModel: MainViewModel(storeRepository: appCoordinator.diContainer.storeRepository))
                .navigationDestination(for: HomeRoute.self) { route in
                    build(route)
                }
        }
    }
    
    @ViewBuilder
    func build(_ route: HomeRoute) -> some View {
        switch route {
        case .storeDetail(let storeId):
            StoreDetailView(viewModel: StoreDetailViewModel(storeRepository: appCoordinator.diContainer.storeRepository, storeId: storeId))
        }
    }
}

// MARK: - OrderCoordinator
final class OrderCoordinator: TabCoordinator {
    @Published private(set) var path = NavigationPath()
    var onLogout: (() -> Void)?
    
    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { _ in }
    }
    
    func requestLogout() {
        path = NavigationPath()
        onLogout?()
    }
    
    func push(_ item: OrderRoute) {
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

struct OrderCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var orderCoordinator: OrderCoordinator
    
    var body: some View {
        EmptyView()
    }
    
    @ViewBuilder
    func build(_ route: OrderRoute) -> some View {
        
    }
}

// MARK: - CommunityCoordinator
final class CommunityCoordinator: TabCoordinator {
    @Published private(set) var path = NavigationPath()
    var onLogout: (() -> Void)?
    
    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { _ in }
    }
    
    func requestLogout() {
        path = NavigationPath()
        onLogout?()
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
                .navigationDestination(for: CommunityRoute.self) { route in
                    build(route)
                }
        }
    }
    
    @ViewBuilder
    func build(_ route: CommunityRoute) -> some View {
        
    }
}

// MARK: - ChatCoordinator
final class ChatCoordinator: TabCoordinator {
    @Published private(set) var path = NavigationPath()
    var onLogout: (() -> Void)?
    
    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { _ in }
    }
    
    func requestLogout() {
        path = NavigationPath()
        onLogout?()
    }
    
    func push(_ route: ChatRoute) {
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

struct ChatCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var chattingCoordinator: ChatCoordinator
    
    var body: some View {
        NavigationStack(path: chattingCoordinator.getPath) {
            ChatRoomListView(viewModel: ChatRoomListViewModel(chatRepository: appCoordinator.diContainer.chatRepository))
                .navigationDestination(for: ChatRoute.self) { route in
                    build(route)
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
        }
    }
}

// MARK: - ProfileCoordinator
class ProfileCoordinator: TabCoordinator {
    @Published var path = NavigationPath()
    var onLogout: (() -> Void)?
    
    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { _ in }
    }
    
    func requestLogout() {
        path = NavigationPath()
        onLogout?()
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
            VStack { }
                .navigationDestination(for: ProfileRoute.self) { route in
                    build(route)
                }
        }
    }
    
    @ViewBuilder
    func build(_ route: ProfileRoute) -> some View {
    }
}
