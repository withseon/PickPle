//
//  OrderMenuResponse.swift
//  PickPle
//
//  Created by 정인선 on 8/9/25.
//

import Foundation

struct OrderMenuResponse: Decodable {
    struct MenuResponse: Decodable {
        let id: String
        let category: String
        let name: String
        let description: String?
        let originInformation: String?
        let price: Int
        let tags: [String]
        let menuImageUrl: String?
        let createdAt: String
        let updatedAt: String
    }
    
    let menu: MenuResponse
    let quantity: Int
}
