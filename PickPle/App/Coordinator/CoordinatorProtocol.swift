//
//  CoordinatorProtocol.swift
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

protocol TabCoordinator: ObservableObject {
    var path: NavigationPath { get }
    var onLogout: (() -> Void)? { get set }
    func popToRoot()
    func pop()
}
