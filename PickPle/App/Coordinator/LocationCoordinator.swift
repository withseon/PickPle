//
//  LocationCoordinator.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import SwiftUI

enum LocationSheetRoute: Identifiable {
    var id: UUID { UUID() }
    case map(_ completion: (() -> Void)?)
}

// MARK: - LocationCoordinator
final class LocationCoordinator: ObservableObject {
    typealias Route = Never
    typealias Sheet = LocationSheetRoute

    @Published var path = NavigationPath()
    @Published private(set) var sheet: Sheet? = nil
    var onLocationSetup: (() -> Void)?

    var getPath: Binding<NavigationPath> {
        Binding { self.path } set: { newPath in self.path = newPath }
    }

    func completeLocationSetUp() {
        onLocationSetup?()
    }

    func push(_ route: Route) { }
    func pop() { }
    func popToRoot() { }

    func presentSheet(_ sheet: Sheet) {
        self.sheet = sheet
    }

    func dismissSheet() {
        self.sheet = nil
    }
}

struct LocationCoordinatorView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var locationCoordinator: LocationCoordinator

    var body: some View {
        InitialLocationSettingView {
            locationCoordinator.completeLocationSetUp()
        }
        .sheet(item: Binding<LocationSheetRoute?>(
            get: { locationCoordinator.sheet },
            set: { _ in locationCoordinator.dismissSheet() }
        )) { sheetItem in
            buildSheet(sheetItem)
        }
    }

    @ViewBuilder
    func buildSheet(_ sheet: LocationSheetRoute) -> some View {
        switch sheet {
        case .map(let completion):
            MapView(onLocationSelected: completion)
        }
    }
}
