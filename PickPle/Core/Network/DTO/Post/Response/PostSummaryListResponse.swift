//
//  PostSummaryListResponse.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation

struct PostSummaryListResponse: Decodable {
    struct PostSummaryResponse: Decodable {
        let postId: String
        let category: String
        let title: String
        let content: String
        let store: StoreSummaryResponse
        let geolocation: GeolocationResponse
        let creator: UserInfoResponse
        let files: [String]
        let is_like: Bool
        let like_count: Int
        let createdAt: String
        let updatedAt: String
    }
    let data: [PostSummaryResponse]
    let nextCursor: String
}
