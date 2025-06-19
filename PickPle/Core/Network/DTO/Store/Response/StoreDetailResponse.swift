//
//  StoreDetailResponse.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation

struct StoreDetailResponse: Decodable {
    struct UserInfoResponse: Decodable {
        let userId: String
        let nick: String
        let profileImage: String?
    }
    
    struct MenuResponse: Decodable {
        let menuId: String
        let storeId: String
        let category: String?
        let name: String?
        let description: String?
        let originInformation: String?
        let price: Int
        let isSoldOut: Bool
        let tags: [String]
        let menuImageUrl: String?
        let createdAt: String
        let updatedAt: String
    }
    
    let storeId: String
    let category: String?
    let name: String?
    let description: String?
    let hashTags: [String]
    let open: String?
    let address: String?
    let estimatedPickupTime: Int
    let parkinGuide: String?
    let storeImageUrls: [String]
    let isPicchelin: Bool
    let isPick: Bool
    let pickCount: Int
    let totalReviewCount: Int
    let totalOrderCount: Int
    let totalRating: Float
    let creator: UserInfoResponse
    let geolocation: GeolocationResponse
    let menuList: [MenuResponse]
    let createdAt: String
    let updatedAt: String
}
