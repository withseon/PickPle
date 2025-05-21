//
//  APIRequestInterceptor.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

final class APIRequestInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, any Error>) -> Void) {
        guard let url = urlRequest.url?.absoluteString else {
            completion(.success(urlRequest))
            return
        }
        
        if url.hasPrefix(APIURL.PICKUP) {
            var urlRequest = urlRequest
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(APIKEY.PICKUP, forHTTPHeaderField: "SesacKey")
            
            // TODO: AccessToken
            print("body::", String(data: urlRequest.httpBody!, encoding: .utf8)!)
            completion(.success(urlRequest))
            return
        }
        
        completion(.success(urlRequest))
    }
}
