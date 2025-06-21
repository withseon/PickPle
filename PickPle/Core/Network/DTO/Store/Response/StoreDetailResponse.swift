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
        return StoreDetail(
            storeId: storeId,
            name: name,
            businessHours: businessHours(open: self.open, close: close),
            address: address ?? "주소 정보가 없습니다.",
            estimatedPickupTime: "누적 주문 \(estimatedPickupTime)회",
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
            menuCategory: menuList
                .compactMap { $0.category }
                .reduce([]) { result, category in
                    result.contains(category) ? result : result + [category]
                },
            MenuList: menuList.map {
                StoreDetail.Menu(
                    menuId: $0.menuId,
                    category: $0.category,
                    name: $0.name,
                    description: $0.description ?? "",
                    price: "\($0.price.formatted())원",
                    isSoldOut: $0.isSoldOut,
                    tags: $0.tags,
                    menuImageUrl: $0.menuImageUrl,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            createdAt: createdAt,
            updatedAt: updatedAt)
    }
    
    private func businessHours(open: String?, close: String?) -> String {
        var openHour = ""
        var closeHour = ""
        
        if let open {
            openHour = FormatHelper.getTime(open, isDetail: true)
        }
        
        if let close {
            closeHour = FormatHelper.getTime(close, isDetail: true)
        }
        
        if openHour.isEmpty && closeHour.isEmpty {
            return "영업시간 정보가 없습니다."
        } else {
            return "매일 \(openHour) ~ \(closeHour)"
        }
    }
}
