//
//  AppCoordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

enum AppRoute: Hashable {
    case splash
    case signIn
    case location
    case main
}

// MARK: - AppCoordinator
final class AppCoordinator: CoordinatorProtocol {
    typealias Route = AppRoute
    typealias Sheet = Never

    @Published private(set) var path = NavigationPath()
    @Published private(set) var diContainer = DIContainer()
    @Published private(set) var sheet: Never? = nil
    @Published private(set) var current: AppRoute = .splash

    // ✅ 탭바 배지용 실시간 안읽은 메시지 개수
    @Published var totalUnreadCount: Int = 0

    // 하위 코디네이터
    @Published var authCoordinator = AuthCoordinator()
    @Published var locationCoordinator = LocationCoordinator()
    @Published var mainCoordinator = MainCoordinator()

    init() {
        setup()
        setupUnreadCountObserver()
    }

    private func setup() {
        authCoordinator.onLogin = { [weak self] in
            guard let self else { return }
            self.handleLoginSuccess() // 일반 로그인
        }

        authCoordinator.onSignUp = { [weak self] in
            guard let self else { return }
            self.handleSignUpSuccess() // 회원가입
        }

        locationCoordinator.onLocationSetup = { [weak self] in
            guard let self else { return }
            self.current = .main
            print("위치 설정 완료 - 메인으로 이동")
        }

        mainCoordinator.onLogout = { [weak self] in
            guard let self else { return }
            current = .signIn
            print("로그아웃 성공")
        }

        // ✅ MainCoordinator 설정
        mainCoordinator.setup()

        // ✅ PaymentManager 결제 성공 콜백 설정
        diContainer.paymentManager.onPaymentSuccess = { [weak self] in
            guard let self else { return }
            // 메인 화면으로 이동 후 주문 탭 선택
            if self.current != .main {
                self.current = .main
            }

            // 현재 홈 탭에서 깊게 들어가 있다면 루트로 이동
            if self.mainCoordinator.selectedTab == .home {
                self.mainCoordinator.homeCoordinator.popToRoot()
            }

            self.mainCoordinator.selectTab(.order)
            print("📱 [AppCoordinator] 결제 완료 후 주문 탭으로 이동")
        }

    }

    // ✅ 안읽은 메시지 개수 업데이트 관찰자 설정
    private func setupUnreadCountObserver() {
        // 앱 배지 업데이트 알림 관찰
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTotalUnreadCount),
            name: NSNotification.Name("UpdateAppBadge"),
            object: nil
        )

        // 안읽은 메시지 개수 변경 알림 관찰
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTotalUnreadCount),
            name: NSNotification.Name("UpdateUnreadCount"),
            object: nil
        )
    }

    @objc func updateTotalUnreadCount() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let newCount = diContainer.realmRepository.getAllUnreadCount()

            // 값이 실제로 변경된 경우에만 업데이트 (불필요한 UI 업데이트 방지)
            if self.totalUnreadCount != newCount {
                self.totalUnreadCount = newCount
                print("📱 탭바 배지 업데이트: \(newCount)")
            }
        }
    }

    func succeedLogin() {
        checkLocationAndNavigate()
        updateTotalUnreadCount()
        print("자동로그인 성공")
    }

    func failedLogin() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            current = .signIn
            print("자동로그인 실패")
        }
    }

    func handleTokenExpiration() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // 사용자 데이터 정리
            UserDefaultsManager.userId = nil
            UserDefaultsManager.userProfile = nil

            // 토큰 캐시 초기화
            Task {
                await TokenManager.shared.clearCache()
            }

            // 로그인 화면으로 이동
            current = .signIn
            print("토큰 만료로 인한 로그아웃 완료")
        }
    }

    private func handleLoginSuccess() {
        // 회원가입이 아닌 일반 로그인의 경우에만 위치 확인
        checkLocationAndNavigate()
        print("로그인 성공")
    }

    private func handleSignUpSuccess() {
        // 회원가입 성공시에는 무조건 위치 설정으로
        current = .location
        print("회원가입 성공 - 위치 설정으로 이동")
    }

    func checkLocationAndNavigate() {
        // ✅ 앱 재설치 후 최초 로그인이면 무조건 위치 설정으로 이동
        if !UserDefaultsManager.hasRunBefore {
            current = .location
            print("앱 재설치 후 최초 로그인 - 위치 설정으로 이동")
            return
        }

        if let location = UserDefaultsManager.selectedLocation {
            current = .main
            print("기존 위치 존재(\(location)) - 메인으로 이동")
        } else {
            current = .location
            print("위치 정보 없음 - 위치 설정으로 이동")
        }
    }

    func navigateToChatRoom(roomId: String, nick: String) {
        print("🎯 채팅방 이동 요청: roomId=\(roomId), nick=\(nick)")

        // 메인 화면으로 먼저 이동 (필요한 경우)
        if current != .main {
            current = .main
        }

        // 약간의 지연을 두어 메인 화면이 완전히 로드되도록 함
        // 1. 채팅 탭으로 이동
        print("📱 채팅 탭으로 이동")
        self.mainCoordinator.selectTab(.chat)

        // 2. 현재 채팅방과 같으면 이동하지 않음
        if ChatStateManager.shared.isCurrentChatRoom(roomId) {
            print("🚫 이미 해당 채팅방에 있습니다")
            return
        }

        // 3. 즉시 새로운 채팅방으로 교체 이동
        print("🔄 새로운 채팅방으로 직접 이동: \(roomId)")

        // 현재 채팅방에 있다면 직접 교체, 아니면 새로 푸시
        if self.mainCoordinator.chatCoordinator.path.isEmpty {
            // 채팅 리스트에 있다면 일반 푸시
            self.mainCoordinator.chatCoordinator.push(.chatRoom(roomId: roomId, nick: nick))
        } else {
            // 다른 채팅방에 있다면 교체
            self.mainCoordinator.chatCoordinator.pushReplacingCurrent(.chatRoom(roomId: roomId, nick: nick))
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
        case .splash:
            SplashView()
        case .signIn:
            AuthCoordinatorView()
                .environmentObject(authCoordinator)
        case .location:
            LocationCoordinatorView()
                .environmentObject(locationCoordinator)
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
    @ObservedObject var coordinator: AppCoordinator

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        coordinator.currentView
            .environmentObject(coordinator)
            .task {
                // 앱 재설치 후 최초 실행이면 자동로그인 시도하지 않음
                if !UserDefaultsManager.hasRunBefore {
                    print("🆕 앱 최초 실행 - 로그인 화면으로 이동")
                    coordinator.failedLogin()
                    return
                }

                // 토큰 존재 여부 사전 확인
                let tokenExists = await TokenManager.shared.exists(forKey: SecureKey.ACCESS_TOKEN)
                if !tokenExists {
                    print("❌ [AppCoordinator] 토큰이 없어서 자동로그인 건너뛰기")
                    UserDefaultsManager.userId = nil
                    coordinator.failedLogin()
                    return
                }
                print("🔍 [AppCoordinator] ACCESS_TOKEN 존재 확인")

                do {
                    let userProfile = try await coordinator.diContainer.userRepository.profile()

                    // userId는 이미 UserRepository에서 저장됨
                    print("✅ 자동로그인 성공 - userId: \(userProfile.userId)")
                    coordinator.succeedLogin()
                } catch {
                    print("❌ 자동로그인 실패: \(error)")
                    // 자동로그인 실패 시 userId 제거
                    UserDefaultsManager.userId = nil
                    coordinator.failedLogin()
                }
            }
    }
}
