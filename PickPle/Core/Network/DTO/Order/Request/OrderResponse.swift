//
//  OrderCreateRequest.swift
//  PickPle
//
//  Created by 정인선 on 8/3/25.
//

import Foundation

struct OrderCreateRequest: RequestableType {
    struct OrderMenuRequest: RequestableType {
        let menuId: String
        let quantity: Int
    }
    let storeId: String
    let orderMenuList: [OrderMenuRequest]
    let totalPrice: Int
}
