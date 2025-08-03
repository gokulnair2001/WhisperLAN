import Foundation
import AVFoundation

struct Configuration {
    // App Info
    static let appName = "WhisperLAN"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // MultipeerConnectivity
    static let serviceType = "whisperlan"
    static let maxPeers = 8
    static let connectionTimeout: TimeInterval = 30
    
    // Audio Settings
    static let sampleRate: Double = 44100.0
    static let numberOfChannels = 1
    static let audioQuality = AVAudioQuality.high
    
    // Security
    static let encryptionSalt = "WhisperLAN"
    static let keyDerivationOutputSize = 32
    
    // UI
    static let maxRecordingDuration: TimeInterval = 300 // 5 minutes
    static let hapticFeedbackEnabled = true
    
    // File Management
    static let maxStoredMessages = 100
    static let audioFileExtension = "m4a"
    
    // Network
    static let discoveryTimeout: TimeInterval = 60
    static let retryAttempts = 3
} 
