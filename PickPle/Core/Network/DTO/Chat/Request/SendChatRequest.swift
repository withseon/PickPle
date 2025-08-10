//
//  SendChatRequest.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import Foundation

struct SendChatRequest: RequestableType {
    var content: String
    var files: [String]
}
