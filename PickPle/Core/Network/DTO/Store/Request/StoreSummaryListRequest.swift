//
//  StoreSummaryListRequest.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation

struct StoreSummaryListRequest: RequestableType {
    let category: String?
    let longitude: Float
    let latitude: Float
    let next: String?
    let limit: Int?
    let orderBy: String?
}
