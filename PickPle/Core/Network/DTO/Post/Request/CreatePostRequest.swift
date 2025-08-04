//
//  CreatePostRequest.swift
//  PickPle
//
//  Created by 정인선 on 8/27/25.
//

import Foundation

struct CreatePostRequest: RequestableType {
    let category: String
    let title: String
    let content: String
    let storeId: String?
    let latitude: Double
    let longitude: Double
    let files: [String]
}

