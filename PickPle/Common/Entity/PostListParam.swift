//
//  PostListParam.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation

struct PostListParam {
    var category: StoreCategory?
    var distance: Int
    var limit: Int?
    var next: String?
    var orderBy: PostOrder?
    
    static var empty: Self {
        return .init(distance: 500)
    }
}
