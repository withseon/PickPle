//
//  TokenResponse.swift
//  PickPle
//
//  Created by 정인선 on 8/2/25.
//

import Foundation

protocol TokenResponse {
    var accessToken: String { get }
    var refreshToken: String { get }
}
