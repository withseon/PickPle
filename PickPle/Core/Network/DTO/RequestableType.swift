//
//  RequestableType.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation

protocol RequestableType: Encodable {
    var toParameter : [String: Any] { get }
}

extension RequestableType {
    var toParameter : [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let object = try? encoder.encode(self) else { return [:] }
        guard let parameter = try? JSONSerialization.jsonObject(with: object) as? [String: Any] else { return [:] }
        return parameter
    }
}
