//
//  CommentResponse.swift
//  PickPle
//
//  Created by Claude on 8/16/25.
//

import Foundation

struct CommentResponse: Decodable {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: CommentCreator
    
    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
    }
}

struct CommentCreator: Decodable {
    let userId: String
    let nick: String
    let profileImage: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}