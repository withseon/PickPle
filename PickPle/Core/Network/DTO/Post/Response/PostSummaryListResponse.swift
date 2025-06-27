//
//  PostSummaryListResponse.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation

struct PostSummaryListResponse: Decodable {
    struct PostSummaryResponse: Decodable {
        struct StoreResponse: Decodable {
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
        
        let postId: String
        let category: String
        let title: String
        let content: String
        let store: StoreResponse
        let geolocation: GeolocationResponse
        let creator: UserInfoResponse
        let files: [String]
        let isLike: Bool
        let likeCount: Int
        let createdAt: String
        let updatedAt: String
    }
    let data: [PostSummaryResponse]
    let nextCursor: String
}

extension PostSummaryListResponse.PostSummaryResponse {
    var postSummary: PostSummary {
        return PostSummary(
            postId: postId,
            category: category,
            title: title,
            content: content,
            storeId: store.id,
            storeName: store.name,
            storeInfo: "\(store.category) • 주소",
            storeImageUrl: store.storeImageUrls.first,
            geolocation: Location(
                latitude: Double(geolocation.latitude),
                longitude: Double(geolocation.longitude),
                address: ""
            ),
            creator: UserInfo(
                userId: creator.userId,
                nickname: creator.nick,
                profileImage: creator.profileImage
            ),
            files: files,
            isLike: isLike,
            likeCount: likeCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            distance: FormatHelper.shared.getDistance(latitude: geolocation.latitude, longitude: geolocation.longitude, unit: .auto),
            createdFromNow: FormatHelper.shared.getTimeAgo(from: createdAt)
        )
    }
}
