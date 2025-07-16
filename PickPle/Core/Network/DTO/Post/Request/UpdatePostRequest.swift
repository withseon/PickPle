//
//  UpdatePostRequest.swift
//  PickPle
//
//  Created by 정인선 on 8/29/25.
//

import Foundation

struct UpdatePostRequest: RequestableType {
    let category: String?
    let title: String?
    let content: String?
    let storeId: String?
    let latitude: Double?
    let longitude: Double?
    let files: [String]?
}

