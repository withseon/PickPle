//
//  CommunityStoreResponse.swift
//  PickPle
//
//  Created by 정인선 on 8/28/25.
//

import Foundation

struct CommunityStoreResponse: Decodable {
    let id: String
    let category: String
    let geolocation: GeolocationResponse
    let updatedAt: String
    let close: String
    let totalReviewCount: Int
    let totalRating: Double
    let totalOrderCount: Int
    let storeImageUrls: [String]
    let hashTags: [String]
    let pickCount: Int
    let createdAt: String
    let name: String
    let isPick: Bool
}
