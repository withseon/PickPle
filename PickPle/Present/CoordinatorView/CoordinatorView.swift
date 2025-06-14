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
    @ObservedObject var coordinator: Coordinator
    private var rootState: RootState { loginObserver.isLogin ? .authenticated(.main) : .login }
    
    var body: some View {
        NavigationStack(path: Binding { coordinator.path } set: { _ in }) {
            setRoot(rootState)
                .navigationDestination(for: PushItem.self) { item in
                    coordinator.build(item)
                }
                .sheet(item: Binding { coordinator.sheet } set: { _ in }) { item in
                    coordinator.buildSheet(item)
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
    
    @ViewBuilder
    private func setRoot(_ item: RootState) -> some View {
        switch item {
        case .login:
            SignInView(viewModel: SignInViewModel(userRepository: coordinator.diContainer.userRepository))
        case .authenticated(let item):
            switch item {
            case .main:
                MainView(viewModel: MainViewModel(storeRepository: coordinator.diContainer.storeRepository))
            }
        }
    }
}
