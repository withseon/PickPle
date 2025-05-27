//
//  RefreshResponse.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
