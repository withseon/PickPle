//
//  OrderCoordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

enum OrderRoute: Hashable {
    case storeDetail(_ storeId: String)
    case menuDetail(storeId: String, menu: DetailMenuItem)
}

// MARK: - OrderCoordinator
final class OrderCoordinator: TabCoordinator {
    @Published private(set) var path = NavigationPath()
    var onLogout: (() -> Void)?

    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { newPath in self.path = newPath }
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
        NavigationStack(path: orderCoordinator.getPath) {
            OrderView(viewModel: OrderViewModel(orderRepository: appCoordinator.diContainer.orderRepository))
                .navigationDestination(for: OrderRoute.self) { route in
                    build(route)
                }
                .onAppear {
                    // 채팅방 상태 초기화
                    ChatStateManager.shared.exitChatRoom()
                }
        }
    }

    @ViewBuilder
    func build(_ route: OrderRoute) -> some View {
        switch route {
        case .storeDetail(let storeId):
            StoreDetailView(
                viewModel: StoreDetailViewModel(
                    storeRepository: appCoordinator.diContainer.storeRepository,
                    orderRepository: appCoordinator.diContainer.orderRepository,
                    storeId: storeId
                ),
                cartManager: appCoordinator.diContainer.cartManager,
                paymentManager: appCoordinator.diContainer.paymentManager
            )
            .addBackButton {
                orderCoordinator.pop()
            }
        case .menuDetail(let storeId, let menuItem):
            MenuDetailView(cartManager: appCoordinator.diContainer.cartManager, storeId: storeId, menuItem: menuItem)
            .addBackButton {
                orderCoordinator.pop()
            }
        }
    }
}
