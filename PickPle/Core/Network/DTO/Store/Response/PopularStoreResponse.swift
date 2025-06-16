//
//  PopularStoreResponse.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation

struct PopularStoreListResponse: Decodable {
    struct PopularStoreResponse: Decodable {
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
        let createdAt: String
        let updatedAt: String
    }
    
    let data: [PopularStoreResponse]
}

extension PopularStoreListResponse.PopularStoreResponse {
    var asPopularStore: PopularStore {
        return PopularStore(
            storeId: storeId,
            category: category,
            name: name,
            close: FormatHelper.closeTime(close),
            mainImageUrl: storeImageUrls[0],
            isPicchelin: isPicchelin,
            isPick: isPick,
            pickCount: pickCount,
            totalOrderCount: "\(totalOrderCount)회",
            distance: FormatHelper.getDistance(latitude: geolocation.latitude, longitude: geolocation.longitude)
        )
    }
}
