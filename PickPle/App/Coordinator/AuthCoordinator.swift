//
//  AuthCoordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

enum AuthRoute: Hashable {
    case signup
}

// MARK: - Auth Coordinator
final class AuthCoordinator: CoordinatorProtocol {
    typealias Route = AuthRoute
    typealias Sheet = Never

    @Published var path = NavigationPath()
    @Published private(set) var sheet: Never? = nil
    var onLogin: (() -> Void)?
    var onSignUp: (() -> Void)?

    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { newPath in self.path = newPath }
    }

    func succeedLogin() {
        path = NavigationPath()
        onLogin?()
    }

    func succeedSignUp() {
        path = NavigationPath()
        onSignUp?()
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
    @EnvironmentObject var authCoordinator: AuthCoordinator

    var body: some View {
        NavigationStack(path: authCoordinator.getPath) {
            SignInView(viewModel: SignInViewModel(userRepository: appCoordinator.diContainer.userRepository))
                .navigationDestination(for: AuthRoute.self) { route in
                    build(route)
                }
        }
    }

    @ViewBuilder
    func build(_ route: AuthRoute) -> some View {
        switch route {
        case .signup:
            SignUpView(viewModel: SignUpViewModel(userRepository: appCoordinator.diContainer.userRepository) {
                authCoordinator.succeedSignUp()
            })
            .addBackButton {
                authCoordinator.pop()
            }
        }
    }
}
