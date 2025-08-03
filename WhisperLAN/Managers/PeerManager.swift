import Foundation
import MultipeerConnectivity
import Combine
import Network

class PeerManager: NSObject, ObservableObject {
    @Published var discoveredPeers: [Peer] = []
    @Published var connectedPeers: [Peer] = []
    @Published var isHosting = false
    @Published var isBrowsing = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var debugMessages: [String] = []
    
    private let serviceType = "whisperlan"
    private let myPeerID: MCPeerID
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    
    private let encryptionManager: EncryptionManager
    private let audioManager: AudioManager
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    // Store MCPeerID objects for discovered peers
    private var discoveredMCPeers: [String: MCPeerID] = [:]
    
    var onMessageReceived: ((Message) -> Void)?
    
    init(encryptionManager: EncryptionManager, audioManager: AudioManager) {
        self.encryptionManager = encryptionManager
        self.audioManager = audioManager
        
        // Generate a unique peer ID based on device name and timestamp
        let deviceName = UIDevice.current.name
        let timestamp = Int(Date().timeIntervalSince1970)
        self.myPeerID = MCPeerID(displayName: "\(deviceName)-\(timestamp)")
        
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        
        // Validate service type format
        guard serviceType.count >= 1 && serviceType.count <= 15,
              serviceType.range(of: "^[a-zA-Z0-9-]+$", options: .regularExpression) != nil else {
            fatalError("Invalid service type: \(serviceType). Must be 1-15 characters, alphanumeric and hyphens only.")
        }
        
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        // Start network monitoring
        startNetworkMonitoring()
        
        addDebugMessage("PeerManager initialized with peer ID: \(myPeerID.displayName)")
        addDebugMessage("Service type: \(serviceType)")
    }
    
    private func addDebugMessage(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter().string(from: Date())
            self.debugMessages.append("[\(timestamp)] \(message)")
            print("WhisperLAN Debug: \(message)")
        }
    }
    
    func startHosting() {
        addDebugMessage("Starting to host...")
        
        // Stop any existing advertising first
        serviceAdvertiser.stopAdvertisingPeer()
        
        // Reset state
        isHosting = false
        connectionStatus = .disconnected
        
        // Force a complete reset with longer delays
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.addDebugMessage("Network reset delay completed...")
            
            // Check network status before proceeding
            if self.networkMonitor.currentPath.status == .satisfied {
                self.addDebugMessage("Network is satisfied, attempting to start hosting...")
                self.serviceAdvertiser.startAdvertisingPeer()
                self.isHosting = true
                self.connectionStatus = .hosting
                self.addDebugMessage("Now hosting - device should be discoverable")
            } else {
                self.addDebugMessage("WARNING: Network is not satisfied, hosting may fail")
                self.serviceAdvertiser.startAdvertisingPeer()
                self.isHosting = true
                self.connectionStatus = .hosting
            }
        }
    }
    
    func stopHosting() {
        addDebugMessage("Stopping hosting...")
        serviceAdvertiser.stopAdvertisingPeer()
        isHosting = false
        connectionStatus = .disconnected
        addDebugMessage("Hosting stopped")
    }
    
    func startBrowsing() {
        addDebugMessage("Starting to browse for peers...")
        
        // Stop any existing browsing first
        serviceBrowser.stopBrowsingForPeers()
        
        // Reset state
        isBrowsing = false
        connectionStatus = .disconnected
        
        // Force a complete reset with longer delays
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.addDebugMessage("Network reset delay completed...")
            
            // Check network status before proceeding
            if self.networkMonitor.currentPath.status == .satisfied {
                self.addDebugMessage("Network is satisfied, attempting to start browsing...")
                self.serviceBrowser.startBrowsingForPeers()
                self.isBrowsing = true
                self.connectionStatus = .browsing
                self.addDebugMessage("Now browsing for peers...")
            } else {
                self.addDebugMessage("WARNING: Network is not satisfied, browsing may fail")
                self.serviceBrowser.startBrowsingForPeers()
                self.isBrowsing = true
                self.connectionStatus = .browsing
            }
        }
    }
    
    func stopBrowsing() {
        addDebugMessage("Stopping browsing...")
        serviceBrowser.stopBrowsingForPeers()
        isBrowsing = false
        connectionStatus = .disconnected
        addDebugMessage("Browsing stopped")
    }
    
    func invitePeer(_ peer: Peer) {
        addDebugMessage("Inviting peer: \(peer.displayName)")
        addDebugMessage("Looking for peer with ID: \(peer.id)")
        addDebugMessage("Current discovered peers: \(discoveredPeers.map { $0.displayName })")
        addDebugMessage("Stored MCPeerIDs: \(discoveredMCPeers.keys)")
        
        // Find the peer in discovered peers
        guard let discoveredPeer = discoveredPeers.first(where: { $0.id == peer.id }) else { 
            addDebugMessage("ERROR: Could not find peer to invite in discoveredPeers list")
            addDebugMessage("Available peer IDs: \(discoveredPeers.map { $0.id })")
            return 
        }
        
        addDebugMessage("Found peer in discovered list: \(discoveredPeer.displayName)")
        
        // Get the stored MCPeerID
        guard let mcPeer = discoveredMCPeers[peer.id] else {
            addDebugMessage("ERROR: Could not find MCPeerID for peer: \(peer.id)")
            addDebugMessage("Available MCPeerIDs: \(discoveredMCPeers.keys)")
            return
        }
        
        addDebugMessage("Found MCPeerID: \(mcPeer.displayName)")
        
        // Send invitation
        serviceBrowser.invitePeer(mcPeer, to: session, withContext: nil, timeout: 30)
        addDebugMessage("Invitation sent to \(peer.displayName) with timeout: 30 seconds")
    }
    
    func sendMessage(_ message: Message, to peer: Peer) {
        addDebugMessage("Attempting to send message to: \(peer.displayName)")
        addDebugMessage("Message ID: \(message.id)")
        addDebugMessage("Audio data size: \(message.audioData.count) bytes")
        
        // Check if peer is connected
        guard connectedPeers.contains(where: { $0.id == peer.id }) else {
            addDebugMessage("ERROR: Peer \(peer.displayName) not found in connectedPeers")
            addDebugMessage("Connected peers: \(connectedPeers.map { $0.displayName })")
            return
        }
        
        // Get the MCPeerID from our stored mapping
        guard let mcPeer = discoveredMCPeers[peer.id] else {
            addDebugMessage("ERROR: Could not find MCPeerID for connected peer: \(peer.id)")
            addDebugMessage("Available MCPeerIDs: \(discoveredMCPeers.keys)")
            return
        }
        
        addDebugMessage("Found MCPeerID for sending: \(mcPeer.displayName)")
        
        do {
            // Check if we have encryption available for this peer
            let hasEncryption = encryptionManager.hasSharedSecret(for: peer.id)
            addDebugMessage("Encryption available for \(peer.displayName): \(hasEncryption)")
            
            let finalAudioData: Data
            let isEncrypted: Bool
            
            if hasEncryption {
                // Encrypt the message data
                addDebugMessage("Encrypting audio data...")
                finalAudioData = try encryptionManager.encrypt(message.audioData, for: peer.id)
                isEncrypted = true
                addDebugMessage("Encryption successful, encrypted size: \(finalAudioData.count) bytes")
            } else {
                // Send unencrypted for now (temporary fallback)
                addDebugMessage("WARNING: No encryption available, sending unencrypted")
                finalAudioData = message.audioData
                isEncrypted = false
                addDebugMessage("Using unencrypted audio data, size: \(finalAudioData.count) bytes")
            }
            
            // Create message wrapper
            let messageWrapper = MessageWrapper(
                id: message.id,
                senderID: message.senderID,
                senderName: message.senderName,
                timestamp: message.timestamp,
                audioData: finalAudioData,
                duration: message.duration,
                isEncrypted: isEncrypted
            )
            
            addDebugMessage("Creating JSON data...")
            let data = try JSONEncoder().encode(messageWrapper)
            addDebugMessage("JSON encoding successful, data size: \(data.count) bytes")
            
            // Debug: Print what we're sending
            let firstBytes = data.prefix(20)
            addDebugMessage("Sending first 20 bytes: \(Array(firstBytes).map { String(format: "%02X", $0) }.joined(separator: " "))")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                addDebugMessage("Sending JSON string (first 200 chars): \(String(jsonString.prefix(200)))")
            }
            
            // Send the data
            try session.send(data, toPeers: [mcPeer], with: .reliable)
            addDebugMessage("Message sent successfully to \(peer.displayName)")
            
        } catch {
            addDebugMessage("ERROR: Failed to send message: \(error.localizedDescription)")
            addDebugMessage("Error details: \(error)")
        }
    }
    

    
    func clearDebugMessages() {
        debugMessages.removeAll()
    }
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkPathUpdate(path)
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        addDebugMessage("Network status changed:")
        addDebugMessage("- Available interfaces: \(path.availableInterfaces.map { $0.type })")
        addDebugMessage("- Is expensive: \(path.isExpensive)")
        addDebugMessage("- Is constrained: \(path.isConstrained)")
        
        let isSatisfied = path.status == .satisfied
        addDebugMessage("- Is satisfied: \(isSatisfied)")
        
        if isSatisfied {
            addDebugMessage("Network is available and satisfied")
        } else {
            addDebugMessage("WARNING: Network is not satisfied - this may cause discovery issues")
        }
    }
    
    func disconnect() {
        addDebugMessage("Disconnecting...")
        networkMonitor.cancel()
        session.disconnect()
        stopHosting()
        stopBrowsing()
        discoveredPeers.removeAll()
        connectedPeers.removeAll()
        discoveredMCPeers.removeAll()
        connectionStatus = .disconnected
        addDebugMessage("Disconnected")
    }
    
    func resetNetworkServices() {
        addDebugMessage("Performing network services reset...")
        
        // Stop all services
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        session.disconnect()
        
        // Reset state
        isHosting = false
        isBrowsing = false
        connectionStatus = .disconnected
        discoveredPeers.removeAll()
        connectedPeers.removeAll()
        discoveredMCPeers.removeAll()
        
        // Wait for complete reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.addDebugMessage("Network services reset completed")
            self.addDebugMessage("Ready to start hosting/browsing again")
        }
    }
    
    enum ConnectionStatus {
        case disconnected
        case hosting
        case browsing
        case connected
    }
}

// MARK: - MCSessionDelegate
extension PeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                // Exchange public keys for encryption
                self.exchangePublicKeys(with: peerID)
                
                let peer = Peer(id: peerID.displayName, displayName: peerID.displayName, isConnected: true)
                if !self.connectedPeers.contains(where: { $0.id == peer.id }) {
                    self.connectedPeers.append(peer)
                }
                self.connectionStatus = .connected
                
            case .notConnected:
                self.connectedPeers.removeAll { $0.id == peerID.displayName }
                if self.connectedPeers.isEmpty {
                    self.connectionStatus = self.isHosting ? .hosting : (self.isBrowsing ? .browsing : .disconnected)
                }
                
            case .connecting:
                break
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        addDebugMessage("Received data from peer: \(peerID.displayName)")
        addDebugMessage("Received data size: \(data.count) bytes")
        
        do {
            // Check if this is a public key exchange
            if data.count == 65 { // P-256 public key size
                addDebugMessage("Processing public key exchange...")
                let sharedSecret = try encryptionManager.generateSharedSecret(with: data)
                encryptionManager.storeSharedSecret(sharedSecret, for: peerID.displayName)
                addDebugMessage("Public key exchange completed successfully")
                return
            }
            
            // Handle message data
            addDebugMessage("Processing message data...")
            
            // Debug: Print first few bytes to see what we're receiving
            let firstBytes = data.prefix(20)
            addDebugMessage("First 20 bytes: \(Array(firstBytes).map { String(format: "%02X", $0) }.joined(separator: " "))")
            
            // Try to convert to string to see if it's readable JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                addDebugMessage("Data as string (first 200 chars): \(String(jsonString.prefix(200)))")
            } else {
                addDebugMessage("Data is not valid UTF-8 string")
            }
            
            // Try to decode as JSON first to see the structure
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    addDebugMessage("JSON structure: \(jsonObject)")
                }
            } catch {
                addDebugMessage("JSONSerialization failed: \(error.localizedDescription)")
            }
            
            let messageWrapper = try JSONDecoder().decode(MessageWrapper.self, from: data)
            addDebugMessage("JSON decoding successful")
            addDebugMessage("Message ID: \(messageWrapper.id)")
            addDebugMessage("Sender: \(messageWrapper.senderName)")
            addDebugMessage("Duration: \(messageWrapper.duration)")
            addDebugMessage("Audio data size: \(messageWrapper.audioData.count) bytes")
            addDebugMessage("Is encrypted: \(messageWrapper.isEncrypted)")
            
            let decryptedData: Data
            
            if messageWrapper.isEncrypted {
                // Decrypt the audio data
                addDebugMessage("Decrypting audio data...")
                decryptedData = try encryptionManager.decrypt(messageWrapper.audioData, from: peerID.displayName)
                addDebugMessage("Decryption successful, decrypted size: \(decryptedData.count) bytes")
            } else {
                // Use unencrypted data directly
                addDebugMessage("Message is unencrypted, using audio data directly")
                decryptedData = messageWrapper.audioData
                addDebugMessage("Using unencrypted audio data, size: \(decryptedData.count) bytes")
            }
            
            let message = Message(
                senderID: messageWrapper.senderID,
                senderName: messageWrapper.senderName,
                audioData: decryptedData,
                duration: messageWrapper.duration,
                isEncrypted: false
            )
            
            addDebugMessage("Message created successfully, calling onMessageReceived")
            
            DispatchQueue.main.async {
                self.onMessageReceived?(message)
                self.addDebugMessage("Message delivered to UI")
            }
            
        } catch {
            addDebugMessage("ERROR: Failed to process received message: \(error.localizedDescription)")
            addDebugMessage("Error type: \(type(of: error))")
            
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    addDebugMessage("JSON data corrupted: \(context.debugDescription)")
                    addDebugMessage("Coding path: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    addDebugMessage("JSON key not found: \(key.stringValue)")
                    addDebugMessage("Context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    addDebugMessage("JSON type mismatch: expected \(type)")
                    addDebugMessage("Context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    addDebugMessage("JSON value not found: expected \(type)")
                    addDebugMessage("Context: \(context.debugDescription)")
                @unknown default:
                    addDebugMessage("Unknown JSON decoding error")
                }
            }
            
            // Print the raw data for debugging
            addDebugMessage("Raw data (first 100 bytes): \(data.prefix(100).map { String(format: "%02X", $0) }.joined(separator: " "))")
            
            // Try to decode as different formats to see what we actually received
            addDebugMessage("Attempting to identify data format...")
            
            // Check if it's just raw audio data
            if data.count > 1000 {
                addDebugMessage("Large data received (\(data.count) bytes) - might be raw audio")
            }
            
            // Check if it's a simple string
            if let stringData = String(data: data, encoding: .utf8) {
                addDebugMessage("Data can be decoded as string: \(stringData.prefix(50))")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    private func exchangePublicKeys(with peerID: MCPeerID) {
        addDebugMessage("Starting public key exchange with: \(peerID.displayName)")
        
        // Send our public key
        let keyData = encryptionManager.publicKeyData
        addDebugMessage("Sending public key (size: \(keyData.count) bytes)")
        
        do {
            try session.send(keyData, toPeers: [peerID], with: .reliable)
            addDebugMessage("Public key sent successfully to: \(peerID.displayName)")
        } catch {
            addDebugMessage("ERROR: Failed to send public key: \(error.localizedDescription)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension PeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.addDebugMessage("Received invitation from: \(peerID.displayName)")
            // Auto-accept invitations for now
            invitationHandler(true, self.session)
            self.addDebugMessage("Accepted invitation from: \(peerID.displayName)")
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.addDebugMessage("ERROR: Failed to start advertising: \(error.localizedDescription)")
            
            // Check if it's the specific -72008 error
            if let nsError = error as NSError?,
               nsError.domain == "NSNetServicesErrorDomain" && nsError.code == -72008 {
                self.addDebugMessage("Detected NSNetServicesErrorDomain -72008 - Network service issue")
                self.addDebugMessage("This usually indicates network configuration problems")
            }
            
            // Reset state
            self.isHosting = false
            self.connectionStatus = .disconnected
            
            // Try to restart advertising with exponential backoff
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.addDebugMessage("Retrying advertising with longer delay...")
                self.serviceAdvertiser.stopAdvertisingPeer()
                
                // Wait even longer before retry
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.addDebugMessage("Starting advertising retry...")
                    self.serviceAdvertiser.startAdvertisingPeer()
                    self.isHosting = true
                    self.connectionStatus = .hosting
                    self.addDebugMessage("Advertising retry completed")
                }
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension PeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            self.addDebugMessage("Found peer: \(peerID.displayName)")
            let peer = Peer(id: peerID.displayName, displayName: peerID.displayName, isConnected: false)
            if !self.discoveredPeers.contains(where: { $0.id == peer.id }) {
                self.discoveredPeers.append(peer)
                // Store the MCPeerID for later use
                self.discoveredMCPeers[peer.id] = peerID
                self.addDebugMessage("Added peer to discovered list: \(peerID.displayName)")
                self.addDebugMessage("Stored MCPeerID for: \(peerID.displayName)")
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.addDebugMessage("Lost peer: \(peerID.displayName)")
            self.discoveredPeers.removeAll { $0.id == peerID.displayName }
            self.discoveredMCPeers.removeValue(forKey: peerID.displayName)
            self.addDebugMessage("Removed peer and MCPeerID for: \(peerID.displayName)")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.addDebugMessage("ERROR: Failed to start browsing: \(error.localizedDescription)")
            
            // Check if it's the specific -72008 error
            if let nsError = error as NSError?,
               nsError.domain == "NSNetServicesErrorDomain" && nsError.code == -72008 {
                self.addDebugMessage("Detected NSNetServicesErrorDomain -72008 - Network service issue")
                self.addDebugMessage("This usually indicates network configuration problems")
            }
            
            // Reset state
            self.isBrowsing = false
            self.connectionStatus = .disconnected
            
            // Try to restart browsing with exponential backoff
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.addDebugMessage("Retrying browsing with longer delay...")
                self.serviceBrowser.stopBrowsingForPeers()
                
                // Wait even longer before retry
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.addDebugMessage("Starting browsing retry...")
                    self.serviceBrowser.startBrowsingForPeers()
                    self.isBrowsing = true
                    self.connectionStatus = .browsing
                    self.addDebugMessage("Browsing retry completed")
                }
            }
        }
    }
}

// MARK: - Message Wrapper for JSON encoding
struct MessageWrapper: Codable {
    let id: UUID
    let senderID: String
    let senderName: String
    let timestamp: Date
    let audioData: Data
    let duration: TimeInterval
    let isEncrypted: Bool
} 