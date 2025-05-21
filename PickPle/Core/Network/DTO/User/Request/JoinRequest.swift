//
//  JoinRequest.swift
//  PickPle
//
//  Created by 정인선 on 5/14/25.
//

import Foundation

struct JoinRequest: RequestableType {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String?
    let deviceToken: String?
    
    init(
        email: String,
        password: String,
        nick: String,
        phoneNum: String? = nil,
        deviceToken: String? = nil
    ) {
        self.email = email
        self.password = password
        self.nick = nick
        self.phoneNum = phoneNum
        self.deviceToken = deviceToken
    }
}
