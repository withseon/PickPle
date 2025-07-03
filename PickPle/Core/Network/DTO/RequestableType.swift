//
//  RequestableType.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation

protocol RequestableType: Encodable {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy { get }
    var toParameter : [String: Any] { get }
}

extension RequestableType {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        return .convertToSnakeCase
    }
    
    var toParameter : [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        guard let object = try? encoder.encode(self) else { return [:] }
        guard let parameter = try? JSONSerialization.jsonObject(with: object) as? [String: Any] else { return [:] }
        return parameter
    }
}
