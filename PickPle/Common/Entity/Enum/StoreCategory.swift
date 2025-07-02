//
//  StoreCategory.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation

enum StoreCategory: String, CaseIterable {
    case coffee, fastfood, dessert, bakery, more
}

extension StoreCategory {
    var title: String {
        switch self {
        case .coffee:
            return "커피"
        case .fastfood:
            return "패스트푸드"
        case .dessert:
            return "디저트"
        case .bakery:
            return "베이커리"
        case .more:
            return "more"
        }
    }
    
    var icon: String {
        return self.rawValue
    }
}
