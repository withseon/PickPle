//
//  SignInParam.swift
//  PickPle
//
//  Created by 정인선 on 5/19/25.
//

import Foundation

struct SignInParam {
    var email: String
    var password: String
    
    static var empty: Self {
        return .init(email: "", password: "")
    }
}
