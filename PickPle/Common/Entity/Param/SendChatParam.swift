//
//  SendChatParam.swift
//  PickPle
//
//  Created by 정인선 on 7/21/25.
//

import Foundation

struct ChatParam {
    var content: String
    var files: [String]
    
    static var empty: Self {
        return .init(content: "", files: [])
    }
}
