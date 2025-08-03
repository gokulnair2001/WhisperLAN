import Foundation
import CryptoKit

class EncryptionManager: ObservableObject {
    private var privateKey: P256.KeyAgreement.PrivateKey
    private var publicKey: P256.KeyAgreement.PublicKey
    private var sharedSecrets: [String: SymmetricKey] = [:]
    
    init() {
        self.privateKey = P256.KeyAgreement.PrivateKey()
        self.publicKey = privateKey.publicKey
    }
    
    var publicKeyData: Data {
        return publicKey.rawRepresentation
    }
    
    func generateSharedSecret(with peerPublicKeyData: Data) throws -> SymmetricKey {
        guard let peerPublicKey = try? P256.KeyAgreement.PublicKey(rawRepresentation: peerPublicKeyData) else {
            throw EncryptionError.invalidPublicKey
        }
        
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        return sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "WhisperLAN".data(using: .utf8)!,
            sharedInfo: Data(),
            outputByteCount: 32
        )
    }
    
    func encrypt(_ data: Data, for peerID: String) throws -> Data {
        guard let key = sharedSecrets[peerID] else {
            throw EncryptionError.noSharedSecret
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decrypt(_ encryptedData: Data, from peerID: String) throws -> Data {
        guard let key = sharedSecrets[peerID] else {
            throw EncryptionError.noSharedSecret
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func storeSharedSecret(_ secret: SymmetricKey, for peerID: String) {
        sharedSecrets[peerID] = secret
    }
    
    func hasSharedSecret(for peerID: String) -> Bool {
        return sharedSecrets[peerID] != nil
    }
    
    enum EncryptionError: Error {
        case invalidPublicKey
        case noSharedSecret
        case encryptionFailed
        case decryptionFailed
    }
} 