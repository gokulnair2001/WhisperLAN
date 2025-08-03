# 📱 WhisperLAN - Peer-to-Peer Voice Messaging

A secure, offline-first voice messaging app for iOS that enables direct communication between nearby devices without internet or third-party servers.

## 🎯 Features

- **🔐 End-to-End Encryption**: All messages are encrypted using CryptoKit with P-256 key exchange
- **📡 Peer Discovery**: Automatic discovery of nearby devices using MultipeerConnectivity
- **🎤 Voice Recording**: High-quality audio recording with AAC compression
- **🔊 Audio Playback**: Built-in audio player with progress tracking
- **📱 Modern UI**: Clean, intuitive SwiftUI interface
- **🌐 Offline-First**: Works completely offline after initial connection
- **🔒 Privacy-Focused**: No accounts, no cloud storage, no data collection

## 🏗️ Architecture

### Core Components

- **PeerManager**: Handles MultipeerConnectivity for peer discovery and communication
- **AudioManager**: Manages audio recording and playback using AVAudioRecorder/AVAudioPlayer
- **EncryptionManager**: Implements end-to-end encryption using CryptoKit
- **Message Model**: Data structure for voice messages with metadata

### Security Implementation

- **Key Exchange**: P-256 elliptic curve key agreement on connection
- **Message Encryption**: AES-GCM encryption for all voice data
- **No Key Storage**: Ephemeral keys generated per session
- **Secure Transmission**: All data encrypted before transmission

## 🚀 Getting Started

### Prerequisites

- iOS 15.0+
- Xcode 14.0+
- Physical iOS device (MultipeerConnectivity doesn't work in simulator)
- Bluetooth and Wi-Fi enabled

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/WhisperLAN.git
cd WhisperLAN
```

2. Open the project in Xcode:
```bash
open WhisperLAN.xcodeproj
```

3. Select your target device (not simulator)

4. Build and run the project (⌘+R)

### Permissions

The app will request the following permissions:
- **Microphone**: For voice recording
- **Local Network**: For peer discovery
- **Bluetooth**: For nearby device discovery

## 📖 Usage Guide

### Discovering Peers

1. Open the **Peers** tab
2. Tap **"Start Hosting"** to make your device discoverable
3. Tap **"Search"** to find nearby devices
4. Tap **"Connect"** on any discovered peer to establish connection

### Sending Voice Messages

1. Ensure you have connected peers (green status indicator)
2. Go to the **Messages** tab
3. Tap **"Record Message"** and speak
4. Tap **"Stop Recording"** when finished
5. Tap **"Send to Peers"** to transmit the message

### Receiving Messages

- Incoming messages appear automatically in the Messages tab
- Tap the play button to listen to received messages
- Messages are automatically decrypted and stored locally

## 🔧 Technical Details

### Audio Format
- **Codec**: AAC (Advanced Audio Coding)
- **Sample Rate**: 44.1 kHz
- **Channels**: Mono
- **Quality**: High

### Network Protocol
- **Framework**: MultipeerConnectivity
- **Transport**: Bluetooth + Peer-to-Peer Wi-Fi
- **Service Type**: `whisperlan`
- **Encryption**: Required for all connections

### Security Features
- **Key Agreement**: ECDH P-256
- **Symmetric Encryption**: AES-GCM-256
- **Key Derivation**: HKDF with SHA-256
- **Perfect Forward Secrecy**: New keys per session

## 🧪 Testing

### Multi-Device Testing
1. Install the app on multiple physical devices
2. Ensure all devices have Bluetooth and Wi-Fi enabled
3. Start hosting on one device
4. Search for peers on other devices
5. Establish connections and test message exchange

### Range Testing
- **Bluetooth Range**: ~10 meters (33 feet)
- **Wi-Fi Direct Range**: ~50 meters (164 feet)
- **Optimal Conditions**: Line of sight, minimal interference

## 🚨 Limitations

- **iOS Simulator**: MultipeerConnectivity doesn't work in simulator
- **Range**: Limited by Bluetooth/Wi-Fi range
- **Background**: Audio recording may be interrupted when app is backgrounded
- **Device Count**: Maximum 8 peers per session (MultipeerConnectivity limit)

## 🔮 Future Enhancements

- [ ] Push-to-talk walkie-talkie mode
- [ ] Group chat functionality
- [ ] Message persistence with Core Data
- [ ] Audio compression improvements (Opus codec)
- [ ] Cross-platform Android version
- [ ] QR code manual pairing
- [ ] Offline message queuing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support, please open an issue on GitHub or contact the development team.

---

**Note**: This app is designed for educational and personal use. Always respect privacy and local regulations when using peer-to-peer communication tools. 