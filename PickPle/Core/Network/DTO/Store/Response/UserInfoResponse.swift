//
//  UserInfoResponse.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation

struct UserInfoResponse: Decodable {
    let userId: String
    let nick: String
    let profileImage: String?
}
