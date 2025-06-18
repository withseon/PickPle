//
//  StoreSearchResponse.swift
//  PickPle
//
//  Created by 정인선 on 6/2/25.
//

import Foundation

struct StoreSearchResponse: Decodable {
    let data: [StoreSummaryResponse]
}
