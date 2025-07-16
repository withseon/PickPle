//
//  OrderWithStatusListResponse.swift
//  PickPle
//
//  Created by 정인선 on 8/3/25.
//

import Foundation

struct OrderWithStatusListResponse: Decodable {
    struct OrderWithStatusResponse: Decodable {
        struct OrderReviewResponse: Decodable {
            let id: String
            let rating: Double
        }
        
        struct OrderStoreSummaryResponse: Decodable {
            let id: String
            let category: String
            let name: String
            let close: String
            let storeImageUrls: [String]
            let hashTags: [String]
            let geolocation: GeolocationResponse
            let createdAt: String
            let updatedAt: String
        }
        
        struct OrderStatusTimelineResponse: Decodable {
            let status: String
            let completed: Bool
            let changedAt: String?
        }
        
        let orderId: String
        let orderCode: String
        let totalPrice: Int
        let review: OrderReviewResponse?
        let store: OrderStoreSummaryResponse
        let orderMenuList: [OrderMenuResponse]
        let currentOrderStatus: String
        let orderStatusTimeline: [OrderStatusTimelineResponse]
        let paidAt: String
        let createdAt: String
        let updatedAt: String
    }
    
    let data: [OrderWithStatusResponse]
}

extension OrderWithStatusListResponse.OrderWithStatusResponse {
    
    /// 30분 기준으로 현재 주문인지 과거 주문인지 판단
    private var isCurrentOrder: Bool {
        // PICKED_UP 상태이고 30분이 지났는지 확인
        guard currentOrderStatus == "PICKED_UP" else {
            return true  // 픽업 완료가 아니면 현재 주문
        }
        
        // 픽업 완료 시간 찾기
        let pickedUpTimeline = orderStatusTimeline.first { $0.status == "PICKED_UP" && $0.completed }
        guard let pickedUpTime = pickedUpTimeline?.changedAt else {
            return true
        }
        
        // FormatHelper를 활용한 30분 경과 여부 확인
        return FormatHelper.shared.isWithin30Minutes(from: pickedUpTime)
    }
    
    /// CurrentOrder로 변환
    var asCurrentOrder: CurrentOrder? {
        guard isCurrentOrder else { return nil }
        
        let statusItems = orderStatusTimeline.map { timeline in
            CurrentOrder.OrderStatusItem(
                status: CurrentOrder.OrderStatusItem.OrderStatus(rawValue: timeline.status) ?? .pendingApproval,
                isCompleted: timeline.completed,
                timeText: timeline.changedAt.map { FormatHelper.shared.getChatTime(from: $0) } ?? ""
            )
        }
        
        let menuItems = orderMenuList.map { orderMenu in
            CurrentOrder.OrderMenuItem(
                name: orderMenu.menu.name,
                price: "\(orderMenu.menu.price.formatted())원",
                quantity: "\(orderMenu.quantity)EA",
                imageUrl: orderMenu.menu.menuImageUrl
            )
        }
        
        let totalQuantity = orderMenuList.reduce(0) { $0 + $1.quantity }
        
        return CurrentOrder(
            orderId: orderId,
            orderCode: orderCode,
            storeId: store.id,
            storeName: store.name,
            menuSummary: createMenuSummary(),
            orderDate: FormatHelper.shared.formatOrderDateTime(paidAt),
            statusTimeline: statusItems,
            menuItems: menuItems,
            totalPrice: "\(totalPrice.formatted())원",
            totalQuantity: "\(totalQuantity)EA"
        )
    }
    
    /// PastOrder로 변환
    var asPastOrder: PastOrder? {
        guard !isCurrentOrder else { return nil }
        
        let firstImageUrl = store.storeImageUrls.first
        
        return PastOrder(
            orderId: orderId,
            orderCode: orderCode,
            storeId: store.id,
            storeName: store.name,
            orderDate: FormatHelper.shared.formatOrderDateTime(paidAt),
            menuSummary: createMenuSummaryForPast(),
            totalPrice: "\(totalPrice.formatted())원",
            storeImageUrl: firstImageUrl,
            hasReview: review != nil,
            reviewRating: String(format: "%.1f", review?.rating ?? "")
        )
    }
    
    // MARK: - Private Helper Methods
    private func createMenuSummary() -> String {
        guard let firstMenu = orderMenuList.first else { return "" }
        return firstMenu.menu.name
    }
    
    private func createMenuSummaryForPast() -> String {
        guard let firstMenu = orderMenuList.first else { return "" }
        
        if orderMenuList.count == 1 {
            return "\(firstMenu.menu.name)"
        } else {
            let totalOtherItems = orderMenuList.dropFirst().reduce(0) { $0 + $1.quantity }
            return "\(firstMenu.menu.name) 외 \(totalOtherItems)건"
        }
    }
}

// MARK: - List Response Extension

extension OrderWithStatusListResponse {
    
    /// 주문 리스트를 현재 주문과 과거 주문으로 분리
    func separateOrders() -> (current: [CurrentOrder], past: [PastOrder]) {
        var currentOrders: [CurrentOrder] = []
        var pastOrders: [PastOrder] = []
        
        for orderResponse in data {
            if let currentOrder = orderResponse.asCurrentOrder {
                currentOrders.append(currentOrder)
            } else if let pastOrder = orderResponse.asPastOrder {
                pastOrders.append(pastOrder)
            }
        }
        
        return (currentOrders, pastOrders)
    }
    
    /// 현재 주문만 반환
    var currentOrders: [CurrentOrder] {
        return data.compactMap { $0.asCurrentOrder }
    }
    
    /// 과거 주문만 반환
    var pastOrders: [PastOrder] {
        return data.compactMap { $0.asPastOrder }
    }
}

struct CurrentOrder {
    let orderId: String
    let orderCode: String
    let storeId: String
    let storeName: String
    let menuSummary: String  // "새싹 도넛 가게"
    let orderDate: String    // "2025년 4월 22일 오후 6:26"
    let statusTimeline: [OrderStatusItem]
    let menuItems: [OrderMenuItem]
    let totalPrice: String
    let totalQuantity: String
    
    struct OrderStatusItem {
        let status: OrderStatus
        let isCompleted: Bool
        let timeText: String  // "오후 6:24"
        
        enum OrderStatus: String, CaseIterable {
            case pendingApproval = "PENDING_APPROVAL"
            case approved = "APPROVED"
            case inProgress = "IN_PROGRESS"
            case readyForPickup = "READY_FOR_PICKUP"
            case pickedUp = "PICKED_UP"
            
            var displayName: String {
                switch self {
                case .pendingApproval: return "승인대기"
                case .approved: return "주문승인"
                case .inProgress: return "조리 중"
                case .readyForPickup: return "픽업대기"
                case .pickedUp: return "픽업완료"
                }
            }
        }
    }
    
    struct OrderMenuItem {
        let name: String
        let price: String
        let quantity: String
        let imageUrl: String?
    }
}

struct PastOrder {
    let orderId: String
    let orderCode: String
    let storeId: String
    let storeName: String
    let orderDate: String     // "2025년 4월 21일 오후 7:21"
    let menuSummary: String   // "새싹 홀케이크 외 3건"
    let totalPrice: String
    let storeImageUrl: String?
    let hasReview: Bool
    let reviewRating: String    // 별점 (5.0 등)
}
