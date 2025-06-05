//
//  StoreSummaryListResponse.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation

struct StoreSummaryListResponse: Decodable {
    struct StoreSummary: Decodable {
        let storeId: String
        let category: String
        let name: String
        let close: String
        let storeImageUrls: String
        let isPicchelin: Bool
        let isPick: Bool
        let pickCount: Int
        let hasTag: [String]
        let totalRating: Float
        let totalOrderCount: Int
        let totalReviewCount: Int
        let geolocation: GeolocationResponse
        let distance: Float
        let createdAt: String
        let updateAt: String
    }
    
    let data: StoreSummary
    let nextCursor: String
}
