//
//  DeviceTokenRequest.swift
//  PickPle
//
//  Created by 정인선 on 7/30/25.
//

import Foundation

struct DeviceTokenRequest: RequestableType {
    let deviceToken: String
    
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        return .useDefaultKeys
    }
}
