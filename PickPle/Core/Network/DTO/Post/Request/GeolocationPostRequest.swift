//
//  GeolocationPostRequest.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation

struct PostSummaryRequest: RequestableType {
    let category: String?
    let longitude: Float
    let latitude: Float
    let maxDistance: Int
    let limit: Int?
    let next: String?
    let orderBy: String?
}
