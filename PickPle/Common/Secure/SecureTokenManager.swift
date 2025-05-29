//
//  SecureTokenManager.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

protocol SecureTokenManagerable {
    func encryptAndStoreToken(token: String, forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void)
    func retrieveAndDecryptToken(forKey key: String, completion: @escaping (Result<String, KeychainError>) -> Void)
    func deleteToken(forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void)
}

final class SecureTokenManager: SecureTokenManagerable {
    static let shared = SecureTokenManager(
        secureEnclaveService: DefaultSecureEnclaveService(),
        keychainService: DefaultKeychainService()
    )
    
    private let secureEnclaveService: SecureEnclaveService
    private let keychainService: KeychainService
    
    private init(
        secureEnclaveService: SecureEnclaveService,
        keychainService: KeychainService
    ) {
        self.secureEnclaveService = secureEnclaveService
        self.keychainService = keychainService
    }
    
    func encryptAndStoreToken(token: String, forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            
            guard let tokenData = token.data(using: .utf8),
                  let encryptedData = secureEnclaveService.encryptData(tokenData: tokenData, forKey: key) else {
                print("❌ \(key) 암호화 실패")
                completion(.failure(.authFailed))
                return
            }
            
            keychainService.deleteData(encryptedData, forKey: key) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func retrieveAndDecryptToken(forKey key: String, completion: @escaping (Result<String, KeychainError>) -> Void) {
        keychainService.retrieveData(forKey: key) { result in
            switch result {
            case .success(let encryptedData):
                DispatchQueue.global().async { [weak self] in
                    guard let self else { return }
                    if let decryptedData = secureEnclaveService.decryptData(encryptData: encryptedData, forKey: key),
                       let token = String(data: decryptedData, encoding: .utf8) {
                        print("✅ 복호화된 \(key): \(token)")
                        completion(.success(token))
                    } else {
                        print("❌ \(key) 복호화 실패")
                        completion(.failure(.authFailed))
                    }
                }
            case .failure:
                print("❌ \(key) 복호화 실패")
                completion(.failure(.authFailed))
            }
        }
    }
    
    func deleteToken(forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void) {
        keychainService.deleteData(forKey: key) { result in
            switch result {
            case .success:
                print("✅ \(key) 데이터 삭제 완료")
                completion(.success(()))
            case .failure(let error):
                print("❌ \(key) 데이터 삭제 실패")
                completion(.failure(error))
            }
        }
    }
}
