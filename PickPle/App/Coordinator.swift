//
//  Coordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

enum PushItem: Hashable {
    case signup
    case storeDetail(_ storeId: String)
}

enum SheetItem: Identifiable {
    var id: UUID { UUID() }
    case map(_ completion: (() -> Void)?)
}

final class Coordinator: ObservableObject {
    @Published private(set) var path = NavigationPath()
    @Published private(set) var sheet: SheetItem?
    @Published private(set) var diContainer = DIContainer()
    
    func push(_ item: PushItem) {
        path.append(item)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func present(_ item: SheetItem) {
        self.sheet = item
    }
}

extension Coordinator {
    @ViewBuilder
    func build(_ item: PushItem) -> some View {
        switch item {
        case .signup:
            let repository = diContainer.userRepository
            SignUpView(viewModel: SignUpViewModel(userRepository: repository))
        case .storeDetail(let storeId):
            let repository = diContainer.storeRepository
            StoreDetailView(viewModel: StoreDetailViewModel(storeRepository: repository, storeId: storeId))
        }
    }
    
    @ViewBuilder
    func buildSheet(_ item: SheetItem) -> some View {
        switch item {
        case .map(let completion):
            MapView(locationManager: diContainer.locationManager, onLocationSelected: completion)
        }
    }
}
