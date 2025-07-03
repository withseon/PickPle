//
//  KakaoLoginRequest.swift
//  PickPle
//
//  Created by 정인선 on 6/9/25.
//

import Foundation

struct KakaoLoginRequest: RequestableType {
    let oauthToken: String
    let deviceToken: String?
    
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        return .useDefaultKeys
    }
}
