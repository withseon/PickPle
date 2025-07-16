//
//  CommentResponse.swift
//  PickPle
//
//  Created by 정인선 on 8/17/25.
//

import Foundation

struct CommentResponse: Decodable {
    let commentId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let creator: UserInfoResponse
}
