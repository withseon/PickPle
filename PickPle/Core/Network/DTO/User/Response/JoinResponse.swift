//
//  JoinResponse.swift
//  PickPle
//
//  Created by 정인선 on 5/17/25.
//

import Foundation

struct JoinResponse: Decodable {
    let userId: String
    let email: String
    let nick: String
    let accessToken: String
    let refreshToken: String
}

extension JoinResponse: TokenResponse { }
