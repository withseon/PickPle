//
//  SignupParam.swift
//  PickPle
//
//  Created by 정인선 on 5/19/25.
//

import Foundation

struct SignUpParam {
    var email: String
    var password: String
    var confirmPassword: String
    var nickname: String
    var phoneNum: String
    
    static var empty: Self {
        return .init(email: "", password: "", confirmPassword: "", nickname: "", phoneNum: "")
    }
}
