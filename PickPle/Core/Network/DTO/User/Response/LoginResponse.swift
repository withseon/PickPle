//
//  EmailLoginResponse.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

struct LoginResponse: Decodable {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
}
