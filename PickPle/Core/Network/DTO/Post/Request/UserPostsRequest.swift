//
//  UserPostsRequest.swift
//  PickPle
//
//  Created by 정인선 on 6/17/25.
//

import Foundation

struct UserPostsRequest: RequestableType {
    let category: String?
    let limit: Int?
    let next: String?
    let userId: String
}
