//
//  ReceiptOrderResponse.swift
//  PickPle
//
//  Created by 정인선 on 8/9/25.
//

import Foundation

struct ReceiptOrderResponse: Decodable {
    struct OrderResponse: Decodable {
        struct OrderStoreSummaryResponse: Decodable {
            let id: String?
            let category: String?
            let name: String?
            let close: String?
            let storeImageUrls: [String]?
            let hasTags: [String]?
            let geolocation: GeolocationResponse
            let createdAt: String?
            let updatedAt: String?
        }
        
        let orderId: String
        let orderCode: String
        let totalPrice: Int
        let store: OrderStoreSummaryResponse
        let orderMenuList: [OrderMenuResponse]
        let paidAt: String
        let createdAt: String
        let updatedAt: String
    }
    
    let paymentId: String
    let orderItem: OrderResponse
    let createdAt: String
    let updatedAt: String
}
