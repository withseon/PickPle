//
//  StoreDetailResponse.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation

struct StoreDetailResponse: Decodable {
    struct MenuResponse: Decodable {
        let menuId: String
        let storeId: String
        let category: String
        let name: String
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
    let category: String
    let name: String
    let description: String?
    let hashTags: [String]
    let open: String?
    let close: String?
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

extension StoreDetailResponse {
    var asStoreDetail: StoreDetail {
        let menuItems = menuList.map { menuData in
            StoreDetail.CategoryItem.MenuItem(
                menuId: menuData.menuId,
                category: menuData.category,
                name: menuData.name,
                description: menuData.description ?? "",
                price: menuData.price,
                priceText: "\(menuData.price.formatted())원",
                isSoldOut: menuData.isSoldOut,
                tags: menuData.tags,
                menuImageUrl: menuData.menuImageUrl,
                createdAt: menuData.createdAt,
                updatedAt: menuData.updatedAt
            )
        }
        
        var uniqueCategories: [String] = []
        var groupedByCategory: [String: [StoreDetail.CategoryItem.MenuItem]] = [:]
        
        for item in menuItems {
            if !uniqueCategories.contains(item.category) {
                uniqueCategories.append(item.category)
                groupedByCategory[item.category] = []
            }
            groupedByCategory[item.category]?.append(item)
        }
        
        let categoryList = uniqueCategories.compactMap { category in
            let items = groupedByCategory[category] ?? []
            return StoreDetail.CategoryItem(title: category, menuList: items)
        }

        
        return StoreDetail(
            storeId: storeId,
            name: name,
            businessHours: businessHours(open: self.open, close: close),
            address: address ?? "주소 정보가 없습니다.",
            estimatedPickupTime: "예상 소요 시간 \(estimatedPickupTime)분 (\(FormatHelper.shared.getDistance(latitude: geolocation.latitude, longitude: geolocation.longitude, unit: .kilometers)))",
            parkinGuide: parkinGuide ?? "주차 정보가 없습니다.",
            storeImageUrls: storeImageUrls,
            isPicchelin: isPicchelin,
            isPick: isPick,
            pickCount: pickCount,
            totalReviewCount: "(\(totalReviewCount))",
            totalOrderCount: "누적 주문 \(totalOrderCount)회",
            totalRating: "\(totalRating)",
            creator: StoreDetail.UserInfo(
                userId: creator.userId,
                nick: creator.nick,
                profileImage: creator.profileImage
            ),
            location: Location(
                latitude: Double(geolocation.latitude),
                longitude: Double(geolocation.longitude),
                address: ""),
            categoryList: categoryList,
            createdAt: createdAt,
            updatedAt: updatedAt)
    }
    
    private func businessHours(open: String?, close: String?) -> String {
        var openHour = ""
        var closeHour = ""
        
        if let open {
            openHour = FormatHelper.shared.getTime(open, isDetail: true)
        }
        
        if let close {
            closeHour = FormatHelper.shared.getTime(close, isDetail: true)
        }
        
        if openHour.isEmpty && closeHour.isEmpty {
            return "영업시간 정보가 없습니다."
        } else {
            return "매일 \(openHour) ~ \(closeHour)"
        }
    }
}
