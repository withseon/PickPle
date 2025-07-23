//
//  StoreOrder.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation

enum StoreOrder: String, CaseIterable, Hashable {
    case distance, orders, reviews
}

extension StoreOrder: SortType {
    var title: String {
        switch self {
        case .distance:
            return "거리순"
        case .orders:
            return "주문순"
        case .reviews:
            return "리뷰 많은 순"
        }
    }
}
