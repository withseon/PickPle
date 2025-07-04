//
//  CoordinatorView.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

private struct IsLoginKey: EnvironmentKey {
    static let defaultValue = LoginObserver()
}

extension EnvironmentValues {
    var isLogin: LoginObserver {
        get { self[IsLoginKey.self] }
        set { self[IsLoginKey.self] = newValue }
    }
}

final class LoginObserver: ObservableObject {
    @Published var isLogin: Bool = false
}

struct CoordinatorView: View {
    enum RootState {
        enum RootItem {
            case main
        }
        
        case login
        case authenticated(RootItem)
    }
    
    @StateObject private var loginObserver = LoginObserver()
    @ObservedObject var coordinator: AppCoordinator
    private var rootState: RootState { loginObserver.isLogin ? .authenticated(.main) : .login }
    
    var body: some View {
        NavigationStack(path: Binding { coordinator.path } set: { _ in }) {
            coordinator.currentView
                .navigationDestination(for: AppRoute.self) { route in
                    coordinator.build(route)
                }
        }
        .environmentObject(loginObserver)
        .task {
            do {
                let _ = try await coordinator.diContainer.userRepository.profile()
                loginObserver.isLogin = true
            } catch {
                loginObserver.isLogin = false
            }
        }
    }
}
