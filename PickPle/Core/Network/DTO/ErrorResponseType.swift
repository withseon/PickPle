//
//  ErrorResponseType.swift
//  PickPle
//
//  Created by 정인선 on 5/14/25.
//

import Foundation

protocol ErrorResponseType: Decodable {
    var message: String { get }
}
