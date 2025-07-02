//
//  UserPostsParam.swift
//  PickPle
//
//  Created by 정인선 on 6/17/25.
//

import Foundation

struct UserPostsParam {
    var category: String?
    var limit: Int?
    var next: String?
    var userId: String
    
    static var empty: UserPostsParam {
        return .init(userId: "")
    }
}
