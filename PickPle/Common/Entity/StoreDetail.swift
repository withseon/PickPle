//
//  StoreDetail.swift
//  PickPle
//
//  Created by 정인선 on 6/6/25.
//

import Foundation

struct StoreDetail {
    struct UserInfo {
        let userId: String
        let nick: String
        let profileImage: String?
    }
    
    struct Menu {
        let menuId: String
        let category: String
        let name: String
        let description: String
        let price: String
        let isSoldOut: Bool
        let tags: [String]
        let menuImageUrl: String?
        let createdAt: String
        let updatedAt: String
    }
    
    let storeId: String
    let category: String
    let name: String
    let description: String
    let open: String
    let address: String
    let estimatedPickupTime: String
    let parkinGuide: String
    let storeImageUrls: [String]
    let isPicchelin: Bool
    let isPick: Bool
    let pickCount: String
    let totalReviewCount: String
    let totalOrderCount: String
    let totalRating: String
    let creator: UserInfo
    let location: Location
    let menuCategory: [String]
    let MenuList: [Menu]
    let createdAt: String
    let updatedAt: String
}
