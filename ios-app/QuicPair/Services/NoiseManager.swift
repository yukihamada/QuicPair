import Foundation
import CryptoKit

class NoiseManager: ObservableObject {
    private var privateKey: Curve25519.KeyAgreement.PrivateKey?
    
    init() {
        loadOrGenerateKey()
    }
    
    private func loadOrGenerateKey() {
        if let keyData = KeychainHelper.load(key: "noisePrivateKey") {
            privateKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: keyData)
        }
        
        if privateKey == nil {
            privateKey = Curve25519.KeyAgreement.PrivateKey()
            if let keyData = privateKey?.rawRepresentation {
                KeychainHelper.save(key: "noisePrivateKey", data: keyData)
            }
        }
    }
    
    var publicKey: Data? {
        privateKey?.publicKey.rawRepresentation
    }
}

struct KeychainHelper {
    static func save(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
}
