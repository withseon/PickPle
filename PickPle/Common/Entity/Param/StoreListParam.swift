//
//  StoreListParam.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation

struct StoreListParam {
    var category: StoreCategory?
    var next: String?
    var limit: Int?
    var orderBy: StoreOrder?
    
    static var empty: Self {
        return .init(limit: 20)
    }
}
