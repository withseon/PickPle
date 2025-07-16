//
//  CreateCommentRequest.swift
//  PickPle
//
//  Created by 정인선 on 8/17/25.
//

import Foundation

struct CreateCommentRequest: RequestableType {
    let parentCommentId: String?
    let content: String
}
