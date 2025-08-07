//
//  CreateCommentRequest.swift
//  PickPle
//
//  Created by Claude on 8/16/25.
//

import Foundation

struct CreateCommentRequest: Encodable {
    let content: String
    let parentCommentId: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case parentCommentId = "parent_comment_id"
    }
    
    init(content: String, parentCommentId: String? = nil) {
        self.content = content
        self.parentCommentId = parentCommentId
    }
}