//
//  OrderStatusChangeRequest.swift
//  PickPle
//
//  Created by 정인선 on 8/3/25.
//

import Foundation

struct OrderStatusUpdateRequest: RequestableType {
    enum OrderStatus: String, CaseIterable, Encodable {
        case pendingApproval = "PENDING_APPROVAL"
        case approved = "APPROVED"
        case inProgress = "IN_PROGRESS"
        case readyForPickup = "READY_FOR_PICKUP"
        case pickedUp = "PICKED_UP"
    }
    
    let nextStatus: OrderStatus
}
