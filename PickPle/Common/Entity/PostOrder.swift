//
//  PostOrder.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation

enum PostOrder: String, CaseIterable {
    case createdAt, likes
}

extension PostOrder {
    var title: String {
        switch self {
        case .createdAt:
            return "최신순"
        case .likes:
            return "인기순"
        }
    }
}
