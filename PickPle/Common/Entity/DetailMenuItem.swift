//
//  DetailMenuItem.swift
//  PickPle
//
//  Created by 정인선 on 8/4/25.
//

import Foundation

struct DetailMenuItem: Hashable {
    let menuId: String
    let name: String
    let description: String
    let price: Int
    let priceText: String
    let isSoldOut: Bool
    let menuImageUrl: String?
}
