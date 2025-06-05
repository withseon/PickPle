//
//  StoreListParam.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation

struct StoreListParam {
    var category: StoreCategory?
    var latitude: Float
    var longitude: Float
    var next: String?
    var orderBy: StoreOrder?
    
    static var empty: Self {
        return .init(category: nil, latitude: 37.654367, longitude: 127.049935, next: nil, orderBy: nil)
    }
}
