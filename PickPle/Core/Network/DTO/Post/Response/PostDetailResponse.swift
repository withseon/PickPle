//
//  PostDetailResponse.swift
//  PickPle
//
//  Created by Claude on 8/17/25.
//

import Foundation

struct PostDetailResponse: Decodable {
    struct PostDetailStore: Decodable {
        let id: String
        let category: String
        let name: String
        let close: String
        let storeImageUrls: [String]
        let isPicchelin: Bool
        let isPick: Bool
        let pickCount: Int
        let hashTags: [String]
        let totalRating: Double
        let totalOrderCount: Int
        let totalReviewCount: Int
        let geolocation: GeolocationResponse
        let createdAt: String
        let updatedAt: String
    }
    
    struct PostComment: Decodable {
        struct CommentReply: Decodable {
            let commentId: String
            let content: String
            let createdAt: String
            let creator: UserInfoResponse
        }

        let commentId: String
        let content: String
        let createdAt: String
        let creator: UserInfoResponse
        let replies: [CommentReply]
    }
    
    let postId: String
    let category: String
    let title: String
    let content: String
    let store: PostDetailStore?
    let geolocation: GeolocationResponse
    let creator: UserInfoResponse
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let comments: [PostComment]
    let createdAt: String
    let updatedAt: String
}

// MARK: - Extension for Entity Conversion
extension PostDetailResponse {
    var asPostDetail: PostDetail {
        return PostDetail(
            postId: postId,
            category: category,
            title: title,
            content: content,
            store: store?.asPostDetailStore,
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
            hasImages: !files.isEmpty,
            isLike: isLike,
            likeCount: likeCount,
            comments: comments.map { $0.asPostDetailComment },
            commentsCount: totalCommentsCount,
            createdAt: createdAt,
            createdAtFormatted: FormatHelper.shared.formatPostDate(createdAt),
            updatedAt: updatedAt
        )
    }
    
    private var totalCommentsCount: Int {
        comments.reduce(0) { count, comment in
            count + 1 + comment.replies.count
        }
    }
}

extension PostDetailResponse.PostDetailStore {
    var asPostDetailStore: PostDetail.Store {
        return PostDetail.Store(
            id: id,
            category: category,
            name: name,
            close: close,
            closeFormatted: FormatHelper.shared.getTime(close),
            storeImageUrls: storeImageUrls,
            isPicchelin: isPicchelin,
            isPick: isPick,
            pickCount: pickCount,
            pickCountFormatted: "Pick \(pickCount)",
            hashTags: hashTags,
            totalRating: totalRating,
            totalRatingFormatted: String(format: "%.1f", totalRating),
            totalOrderCount: totalOrderCount,
            totalOrderCountFormatted: "주문 \(totalOrderCount)회",
            totalReviewCount: totalReviewCount,
            totalReviewCountFormatted: "리뷰 \(totalReviewCount)개",
            geolocation: Location(
                latitude: Double(geolocation.latitude),
                longitude: Double(geolocation.longitude),
                address: ""
            ),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension PostDetailResponse.PostComment {
    var asPostDetailComment: PostDetail.Comment {
        return PostDetail.Comment(
            commentId: commentId,
            content: content,
            createdAt: createdAt,
            createdAtFormatted: FormatHelper.shared.formatCommentDateTime(createdAt),
            creator: UserInfo(
                userId: creator.userId,
                nickname: creator.nick,
                profileImage: creator.profileImage
            ),
            replies: replies.map { $0.asPostDetailCommentReply }
        )
    }
}

extension PostDetailResponse.PostComment.CommentReply {
    var asPostDetailCommentReply: PostDetail.Comment.CommentReply {
        return PostDetail.Comment.CommentReply(
            commentId: commentId,
            content: content,
            createdAt: createdAt,
            createdAtFormatted: FormatHelper.shared.formatCommentDateTime(createdAt),
            creator: UserInfo(
                userId: creator.userId,
                nickname: creator.nick,
                profileImage: creator.profileImage
            )
        )
    }
}
