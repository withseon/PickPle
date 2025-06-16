//
//  StoreSummary.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import Foundation

struct StoreSummary: Equatable {
    let storeId: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    let isPicchelin: Bool
    var isPick: Bool
    var pickCount: Int
    let hashTags: [String]
    let totalRating: String
    let totalOrderCount: String
    let totalReviewCount: String
    let distance: String
}
