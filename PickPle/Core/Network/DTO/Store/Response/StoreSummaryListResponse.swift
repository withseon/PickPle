//
//  StoreSummaryListResponse.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation

struct StoreSummaryListResponse: Decodable {
    let data: [StoreSummaryResponse]
    let nextCursor: String
}
