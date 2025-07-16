//
//  UserProfile.swift
//  PickPle
//
//  Created by 정인선 on 6/12/25.
//

import Foundation

struct UserProfile: Codable {
    let userId: String
    var email: String?
    var nickname: String
    var profileImage: String?
    var phoneNum: String?
}
