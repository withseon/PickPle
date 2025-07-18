//
//  HomeCoordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

enum HomeRoute: Hashable {
    case storeDetail(_ storeId: String)
    case menuDetail(storeId: String, menu: DetailMenuItem)
}

enum HomeSheetRoute: Identifiable {
    var id: UUID { UUID() }
    case map(_ completion: (() -> Void)?)
    case sort(selectedItem: StoreOrder, completion: ((StoreOrder) -> Void)?)
}

enum HomeFullScreenSheetRoute: Identifiable {
    var id: UUID { UUID() }
    case webView(url: URL)
    case payment
}

// MARK: - HomeCoordinator
final class HomeCoordinator: TabCoordinator {
    @Published private(set) var path = NavigationPath()
    @Published private(set) var sheet: HomeSheetRoute? = nil
    @Published private(set) var fullScreenSheet: HomeFullScreenSheetRoute? = nil

    var onLogout: (() -> Void)?

    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { newPath in self.path = newPath }
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

    func presentSheet(_ sheet: HomeSheetRoute) {
        self.sheet = sheet
    }

    func presentFullScreenSheet(_ sheet: HomeFullScreenSheetRoute) {
        fullScreenSheet = sheet
    }

    func dismissSheet() {
        sheet = nil
    }

    func dismissCover() {
        fullScreenSheet = nil
    }
}

struct HomeCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var homeCoordinator: HomeCoordinator

    var body: some View {
        NavigationStack(path: homeCoordinator.getPath) {
            MainView(
                viewModel: MainViewModel(
                    storeRepository: appCoordinator.diContainer.storeRepository,
                    bannerRepository: appCoordinator.diContainer.bannerRepository
                )
            )
            .navigationDestination(for: HomeRoute.self) { route in
                build(route)
            }
            .sheet(item: Binding<HomeSheetRoute?>(
                get: { homeCoordinator.sheet },
                set: { _ in homeCoordinator.dismissSheet() }
            )) {
                sheetItem in buildSheet(sheetItem)
            }
            .fullScreenCover(item: Binding<HomeFullScreenSheetRoute?>(
                get: { homeCoordinator.fullScreenSheet },
                set: { _ in homeCoordinator.dismissCover() }
            )) { sheetItem in
                buildFullScreenSheet(sheetItem)
            }
            .onAppear {
                ChatStateManager.shared.exitChatRoom()
            }
        }
    }

    @ViewBuilder
    func build(_ route: HomeRoute) -> some View {
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
        case .menuDetail(let storeId, let menuItem):
            MenuDetailView(cartManager: appCoordinator.diContainer.cartManager, storeId: storeId, menuItem: menuItem)
        }
    }

    @ViewBuilder
    func buildSheet(_ sheet: HomeSheetRoute) -> some View {
        switch sheet {
        case .map(let completion):
            MapView {
                completion?()
            }
        case .sort(let selectedItem, let completion):
            SortBottomView(selectedItem: selectedItem) { selectedItem in
                completion?(selectedItem)
            }
        }
    }

    @ViewBuilder
    func buildFullScreenSheet(_ sheet: HomeFullScreenSheetRoute) -> some View {
        switch sheet {
        case .webView(let url):
            BridgeWebViewSheet(url: url)
        case .payment:
            PaymentView(paymentManager: appCoordinator.diContainer.paymentManager)
        }
    }
}
