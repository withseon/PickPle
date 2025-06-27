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
    let storeInfo: String
    let storeImageUrl: String?
    
    let geolocation: Location
    let creator: UserInfo
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let createdAt: String
    let updatedAt: String
    
    let distance: String
    let createdFromNow: String
}
