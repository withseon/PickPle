//
//  EmailLoginRequest.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

struct EmailLoginRequest: RequestableType {
    let email: String
    let password: String
    let deviceToken: String?
}
