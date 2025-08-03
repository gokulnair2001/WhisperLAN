import Foundation
import CryptoKit

struct Message: Identifiable, Codable {
    let id: UUID
    let senderID: String
    let senderName: String
    let timestamp: Date
    let audioData: Data
    let duration: TimeInterval
    let isEncrypted: Bool
    
    init(senderID: String, senderName: String, audioData: Data, duration: TimeInterval, isEncrypted: Bool = true) {
        self.id = UUID()
        self.senderID = senderID
        self.senderName = senderName
        self.timestamp = Date()
        self.audioData = audioData
        self.duration = duration
        self.isEncrypted = isEncrypted
    }
}

struct Peer: Identifiable, Hashable {
    let id: String
    let displayName: String
    let isConnected: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Peer, rhs: Peer) -> Bool {
        lhs.id == rhs.id
    }
} 