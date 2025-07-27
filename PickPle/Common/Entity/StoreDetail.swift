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
    
    struct CategoryItem: Hashable {
        struct MenuItem: Hashable, Equatable {
            let menuId: String
            let category: String
            let name: String
            let description: String
            let price: Int
            let priceText: String
            let isSoldOut: Bool
            let tags: [String]
            let menuImageUrl: String?
            let createdAt: String
            let updatedAt: String
        }
        
        let title: String
        let menuList: [MenuItem]
    }
    
    let storeId: String
    let name: String
    let businessHours: String
    let address: String
    let estimatedPickupTime: String
    let parkinGuide: String
    let storeImageUrls: [String]
    let isPicchelin: Bool
    let isPick: Bool
    let pickCount: Int
    let totalReviewCount: String
    let totalOrderCount: String
    let totalRating: String
    let creator: UserInfo
    let location: Location
    let categoryList: [CategoryItem]
    let createdAt: String
    let updatedAt: String
}

extension StoreDetail {
    static let empty = StoreDetail(
        storeId: "",
        name: "",
        businessHours: "",
        address: "",
        estimatedPickupTime: "",
        parkinGuide: "",
        storeImageUrls: [],
        isPicchelin: false,
        isPick: false,
        pickCount: 0,
        totalReviewCount: "",
        totalOrderCount: "",
        totalRating: "",
        creator: UserInfo(
            userId: "",
            nick: "",
            profileImage: nil
        ),
        location: Location(
            latitude: 0.0,
            longitude: 0.0,
            address: ""
        ),
        categoryList: [],
        createdAt: "",
        updatedAt: "")
}

extension StoreDetail.CategoryItem.MenuItem {
    var asDetailMenuItem: DetailMenuItem {
        DetailMenuItem(
            menuId: menuId,
            name: name,
            description: description,
            price: price,
            priceText: priceText,
            isSoldOut: isSoldOut,
            menuImageUrl: menuImageUrl)
    }
}
