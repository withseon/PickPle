//
//  SecureEnclaveService.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

protocol SecureEnclaveService {
    func encryptData(tokenData: Data, forKey key: String) -> Data?
    func decryptData(encryptData: Data, forKey key: String) -> Data?
}

final class DefaultSecureEnclaveService: SecureEnclaveService {
    // MARK: 데이터 암호화
    func encryptData(tokenData: Data, forKey key: String) -> Data? {
        #if targetEnvironment(simulator)
        print("🖥️ 시뮬레이터: 암호화 없이 데이터 반환")
        return tokenData
        #else
        guard let privateKey = readOrCreateSecureEnclaveKey(forKey: key),
              let publicKey = SecKeyCopyPublicKey(privateKey) else { return nil }
        
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(
            publicKey,
            .eciesEncryptionStandardX963SHA256AESGCM,
            tokenData as CFData,
            &error
        ) else {
            print("❌ 데이터 암호화 실패: \(error!.takeRetainedValue())")
            return nil
        }
        
        return encryptedData as Data
        #endif
    }
    
    // MARK: 데이터 복호화 (시뮬레이터 대응)
    func decryptData(encryptData: Data, forKey key: String) -> Data? {
        #if targetEnvironment(simulator)
        print("🖥️ 시뮬레이터: 암호화 없이 데이터 반환")
        return encryptData
        #else
        guard let privateKey = readOrCreateSecureEnclaveKey(forKey: key) else { return nil }
        
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .eciesEncryptionStandardX963SHA256AESGCM,
            encryptData as CFData,
            &error
        ) else {
            print("❌ 데이터 복호화 실패: \(error!.takeRetainedValue())")
            return nil
        }
        
        return decryptedData as Data
        #endif
    }
}

extension DefaultSecureEnclaveService {
    // ✅ Secure Enclave 키 생성
    private func readOrCreateSecureEnclaveKey(forKey key: String) -> SecKey? {
        let tag = key.data(using: .utf8)!
        
        #if targetEnvironment(simulator)
        print("🖥️ 시뮬레이터: Secure Enclave 미지원")
        return nil
        #else
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            print("🔑 기존 Secure \(key) 키 사용")
            return (item as! SecKey)
        }
        
        // 키 생성
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrApplicationTag as String: tag,
                kSecAttrIsPermanent as String: true
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            print("❌ Secure 키 생성 실패: \(error!.takeRetainedValue())")
            return nil
        }
        
        print("🔑 새 Secure 키 생성 완료")
        return privateKey
        #endif
    }
}
