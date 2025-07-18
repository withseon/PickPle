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
        print("🔐 [SecureEnclaveService] decryptData 시작 - key: \(key), 데이터 크기: \(encryptData.count)bytes")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        #if targetEnvironment(simulator)
        print("🖥️ 시뮬레이터: 암호화 없이 데이터 반환")
        return encryptData
        #else
        print("🔐 [SecureEnclaveService] SecureEnclave 키 조회 시작")
        let keyStartTime = CFAbsoluteTimeGetCurrent()
        
        guard let privateKey = readOrCreateSecureEnclaveKey(forKey: key) else { 
            let keyElapsedTime = CFAbsoluteTimeGetCurrent() - keyStartTime
            print("❌ [SecureEnclaveService] SecureEnclave 키 조회 실패 - 소요시간: \(keyElapsedTime)초")
            return nil 
        }
        
        let keyElapsedTime = CFAbsoluteTimeGetCurrent() - keyStartTime
        print("✅ [SecureEnclaveService] SecureEnclave 키 조회 성공 - 소요시간: \(keyElapsedTime)초")
        
        print("🔐 [SecureEnclaveService] SecKeyCreateDecryptedData 시작")
        let decryptStartTime = CFAbsoluteTimeGetCurrent()
        
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .eciesEncryptionStandardX963SHA256AESGCM,
            encryptData as CFData,
            &error
        ) else {
            let decryptElapsedTime = CFAbsoluteTimeGetCurrent() - decryptStartTime
            print("❌ [SecureEnclaveService] 데이터 복호화 실패 - 소요시간: \(decryptElapsedTime)초, 에러: \(error!.takeRetainedValue())")
            return nil
        }
        
        let decryptElapsedTime = CFAbsoluteTimeGetCurrent() - decryptStartTime
        let totalElapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        print("✅ [SecureEnclaveService] 데이터 복호화 성공 - 복호화 시간: \(decryptElapsedTime)초, 총 시간: \(totalElapsedTime)초")
        
        return decryptedData as Data
        #endif
    }
}

extension DefaultSecureEnclaveService {
    // ✅ Secure Enclave 키 생성
    private func readOrCreateSecureEnclaveKey(forKey key: String) -> SecKey? {
        print("🔐 [SecureEnclaveService] readOrCreateSecureEnclaveKey 시작 - key: \(key)")
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
        
        print("🔐 [SecureEnclaveService] SecItemCopyMatching 호출 시작 (키 조회)")
        let searchStartTime = CFAbsoluteTimeGetCurrent()
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        let searchElapsedTime = CFAbsoluteTimeGetCurrent() - searchStartTime
        print("🔐 [SecureEnclaveService] SecItemCopyMatching 완료 - 소요시간: \(searchElapsedTime)초, status: \(status)")
        
        if status == errSecSuccess {
            print("✅ [SecureEnclaveService] 기존 Secure \(key) 키 사용")
            return (item as! SecKey)
        }
        
        print("🔐 [SecureEnclaveService] 기존 키 없음, 새 키 생성 시작")
        
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
        
        print("🔐 [SecureEnclaveService] SecKeyCreateRandomKey 호출 시작")
        let createStartTime = CFAbsoluteTimeGetCurrent()
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            let createElapsedTime = CFAbsoluteTimeGetCurrent() - createStartTime
            print("❌ [SecureEnclaveService] Secure 키 생성 실패 - 소요시간: \(createElapsedTime)초, 에러: \(error!.takeRetainedValue())")
            return nil
        }
        
        let createElapsedTime = CFAbsoluteTimeGetCurrent() - createStartTime
        print("✅ [SecureEnclaveService] 새 Secure 키 생성 완료 - 소요시간: \(createElapsedTime)초")
        return privateKey
        #endif
    }
}
