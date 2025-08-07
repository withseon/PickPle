//
//  CreatePostResponse.swift
//  PickPle
//
//  Created by 정인선 on 8/27/25.
//

import Foundation

struct CreatePostResponse: Decodable {
    let postId: String
    let category: String
    let title: String
    let content: String
    let storeId: CommunityStoreResponse?
    let geolocation: GeolocationResponse
    let creator: UserInfoResponse
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let comments: [CommentResponse]
    let createdAt: String
    let updatedAt: String
}
