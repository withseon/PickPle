//
//  OrderCreateResponse.swift
//  PickPle
//
//  Created by 정인선 on 8/3/25.
//

import Foundation

struct OrderCreateResponse: Decodable {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let createdAt: String
    let updatedAt: String
}
