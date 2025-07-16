//
//  BannerListResponse.swift
//  PickPle
//
//  Created by 정인선 on 7/30/25.
//

import Foundation

struct BannerListResponse: Decodable {
    struct BannerResponse: Decodable {
        struct PayloadResponse: Decodable {
            let type: String
            let value: String
        }
        
        let name: String
        let imageUrl: String
        let payload: PayloadResponse
    }
    let data: [BannerResponse]
}

extension BannerListResponse.BannerResponse {
    var asBannerItem: BannerItem {
        return BannerItem(
            name: name,
            imageUrl: imageUrl,
            type: payload.type,
            value: payload.value
        )
    }
}
