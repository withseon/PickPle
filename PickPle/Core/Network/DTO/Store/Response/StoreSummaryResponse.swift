//
//  StoreSummaryResponse.swift
//  PickPle
//
//  Created by 정인선 on 6/2/25.
//

import Foundation

struct StoreSummaryResponse: Decodable {
    let storeId: String
    let category: String
    let name: String
    let close: String
    let storeImageUrls: [String]
    let isPicchelin: Bool
    let isPick: Bool
    let pickCount: Int
    let hashTags: [String]
    let totalRating: Float
    let totalOrderCount: Int
    let totalReviewCount: Int
    let geolocation: GeolocationResponse
    let distance: Float
    let createdAt: String
    let updatedAt: String
}

extension StoreSummaryResponse {
    var asStoreSummary: StoreSummary {
        return StoreSummary(
            storeId: storeId,
            category: category,
            name: name,
            close: FormatHelper.getTime(close),
            storeImageUrls: storeImageUrls,
            isPicchelin: isPicchelin,
            isPick: isPick,
            pickCount: pickCount,
            hashTags: hashTags,
            totalRating: "\(totalRating)",
            totalOrderCount: "\(totalOrderCount)회",
            totalReviewCount: "(\(totalReviewCount))",
            distance: FormatHelper.formatDistance(Double(distance))
        )
    }
}
