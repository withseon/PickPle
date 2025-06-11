//
//  CoordinatorView.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

struct CoordinatorView: View {
    enum RootItem {
        case login, main
    }
    
    @ObservedObject var coordinator: Coordinator
    let rootItem: RootItem
    
    var body: some View {
        NavigationStack(path: Binding { coordinator.path } set: { _ in }) {
            setRoot(rootItem)
                .navigationDestination(for: PushItem.self) { item in
                    coordinator.build(item)
                }
                .sheet(item: Binding { coordinator.sheet } set: { _ in }) { item in
                    coordinator.buildSheet(item)
                }
        }
    }
    
    @ViewBuilder
    private func setRoot(_ item: RootItem) -> some View {
        switch item {
        case .login:
            SignInView(viewModel: SignInViewModel(userRepository: coordinator.diContainer.userRepository))
        case .main:
            MainView(viewModel: MainViewModel(storeRepository: coordinator.diContainer.storeRepository))
        }
    }
}
