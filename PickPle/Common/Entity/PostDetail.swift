//
//  PostDetail.swift
//  PickPle
//
//  Created by Claude on 8/22/25.
//

import Foundation

struct PostDetail: Equatable, Hashable {
    struct Store: Equatable, Hashable {
        let id: String
        let category: String
        let name: String
        let close: String
        let closeFormatted: String
        let storeImageUrls: [String]
        let isPicchelin: Bool
        let isPick: Bool
        let pickCount: Int
        let pickCountFormatted: String
        let hashTags: [String]
        let totalRating: Double
        let totalRatingFormatted: String
        let totalOrderCount: Int
        let totalOrderCountFormatted: String
        let totalReviewCount: Int
        let totalReviewCountFormatted: String
        let geolocation: Location
        let createdAt: String
        let updatedAt: String
    }
    
    struct Comment: Equatable, Hashable {
        struct CommentReply: Equatable, Hashable {
            let commentId: String
            let content: String
            let createdAt: String
            let createdAtFormatted: String
            let creator: UserInfo
        }
        
        let commentId: String
        let content: String
        let createdAt: String
        let createdAtFormatted: String
        let creator: UserInfo
        var replies: [CommentReply]
    }
    
    let postId: String
    let category: String
    let title: String
    let content: String
    let store: Store?
    let geolocation: Location
    let creator: UserInfo
    let files: [String]
    let hasImages: Bool
    let isLike: Bool
    let likeCount: Int
    var comments: [Comment]
    var commentsCount: Int
    let createdAt: String
    let createdAtFormatted: String
    let updatedAt: String
}
