//
//  MyProfileResponse.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

struct MyProfileResponse: Decodable {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let phoneNum: String?
}
