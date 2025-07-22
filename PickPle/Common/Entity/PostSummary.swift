//
//  PostSummary.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation

struct PostSummary: Equatable {
    let postId: String
    let category: String
    let title: String
    let content: String

    let storeId: String
    let storeName: String
    let storeImageUrl: String?

    var geolocation: Location  // var로 변경 - address 업데이트 가능
    let creator: UserInfo
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let createdAt: String
    let updatedAt: String

    let distance: String
    let createdFromNow: String
}
