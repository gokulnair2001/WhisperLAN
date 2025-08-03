import SwiftUI
import Network
import MultipeerConnectivity
import AVFoundation

class PermissionRequestManager: NSObject, ObservableObject, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate, NetServiceDelegate, NetServiceBrowserDelegate {
    var onPermissionRequested: (() -> Void)?
    private var tempAdvertiser: MCNearbyServiceAdvertiser?
    private var tempBrowser: MCNearbyServiceBrowser?
    private var netService: NetService?
    private var netServiceBrowser: NetServiceBrowser?
    private var networkListener: NWListener?
    private var networkConnection: NWConnection?
    
    func requestLocalNetworkPermission() {
        print("🔍 Starting Local Network permission request...")
        
        // Method 1: Use NetService (Bonjour) - This is the PRIMARY way to trigger Local Network permission
        setupBonjourServices()
        
        // Method 2: Use Network Framework connections
        setupNetworkConnections()
        
        // Method 3: Use MultipeerConnectivity as backup
        setupMultipeerConnectivity()
        
        // Clean up after a reasonable time
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.cleanup()
            self.onPermissionRequested?()
        }
    }
    
    // MARK: - Bonjour Services (Primary Method)
    
    private func setupBonjourServices() {
        print("🔍 Setting up Bonjour services...")
        
        // Create a NetService for TCP
        let tcpService = NetService(domain: "local.", type: "_whisperlan._tcp", name: "WhisperLAN-TCP", port: 8080)
        tcpService.delegate = self
        self.netService = tcpService
        
        // Create a NetServiceBrowser to search for services
        let browser = NetServiceBrowser()
        browser.delegate = self
        self.netServiceBrowser = browser
        
        // Publish the service - THIS IS THE KEY ACTION THAT TRIGGERS LOCAL NETWORK PERMISSION
        print("🔍 Publishing Bonjour service...")
        tcpService.publish()
        
        // Also search for services
        print("🔍 Searching for Bonjour services...")
        browser.searchForServices(ofType: "_whisperlan._tcp", inDomain: "local.")
    }
    
    // MARK: - Network Framework Connections
    
    private func setupNetworkConnections() {
        print("🔍 Setting up Network Framework connections...")
        
        // Create a TCP listener
        do {
            let listener = try NWListener(using: NWParameters.tcp, on: NWEndpoint.Port(integerLiteral: 8081))
            listener.stateUpdateHandler = { state in
                print("🔍 TCP Listener state: \(state)")
            }
            listener.start(queue: DispatchQueue.global())
            self.networkListener = listener
        } catch {
            print("🔍 Failed to create TCP listener: \(error)")
        }
        
        // Create a UDP connection
        let udpEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host("127.0.0.1"), port: NWEndpoint.Port(integerLiteral: 8082))
        let udpConnection = NWConnection(to: udpEndpoint, using: NWParameters.udp)
        udpConnection.stateUpdateHandler = { state in
            print("🔍 UDP Connection state: \(state)")
        }
        udpConnection.start(queue: DispatchQueue.global())
        self.networkConnection = udpConnection
        
        // Send test data
        let testData = "test".data(using: .utf8) ?? Data()
        udpConnection.send(content: testData, completion: .contentProcessed { error in
            if let error = error {
                print("🔍 UDP send error: \(error)")
            } else {
                print("🔍 UDP data sent successfully")
            }
        })
    }
    
    // MARK: - MultipeerConnectivity (Backup Method)
    
    private func setupMultipeerConnectivity() {
        print("🔍 Setting up MultipeerConnectivity...")
        
        let tempPeerID = MCPeerID(displayName: "temp-\(UUID().uuidString)")
        
        // Create advertiser and browser
        let advertiser = MCNearbyServiceAdvertiser(peer: tempPeerID, discoveryInfo: nil, serviceType: "whisperlan")
        let browser = MCNearbyServiceBrowser(peer: tempPeerID, serviceType: "whisperlan")
        
        advertiser.delegate = self
        browser.delegate = self
        
        self.tempAdvertiser = advertiser
        self.tempBrowser = browser
        
        // Start both
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        
        // Create session and try to send data
        let session = MCSession(peer: tempPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let testData = "test".data(using: .utf8) ?? Data()
            try? session.send(testData, toPeers: [], with: .reliable)
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        print("🔍 Cleaning up network services...")
        
        netService?.stop()
        netServiceBrowser?.stop()
        networkListener?.cancel()
        networkConnection?.cancel()
        tempAdvertiser?.stopAdvertisingPeer()
        tempBrowser?.stopBrowsingForPeers()
        
        netService = nil
        netServiceBrowser = nil
        networkListener = nil
        networkConnection = nil
        tempAdvertiser = nil
        tempBrowser = nil
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("🔍 Received invitation from peer: \(peerID.displayName)")
        invitationHandler(true, nil)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("🔍 Failed to start advertising: \(error.localizedDescription)")
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔍 Found peer: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("🔍 Lost peer: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("🔍 Failed to start browsing: \(error.localizedDescription)")
    }
    
    // MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("🔍 Session state changed for peer \(peerID.displayName): \(state.rawValue)")
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("🔍 Received data from peer \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("🔍 Received stream from peer \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("🔍 Started receiving resource from peer \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("🔍 Finished receiving resource from peer \(peerID.displayName)")
    }
    
    // MARK: - NetServiceDelegate
    
    func netServiceWillPublish(_ sender: NetService) {
        print("🔍 NetService will publish: \(sender.name)")
    }
    
    func netServiceDidPublish(_ sender: NetService) {
        print("🔍 NetService did publish: \(sender.name) - THIS SHOULD TRIGGER LOCAL NETWORK PERMISSION!")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("🔍 NetService did not publish: \(sender.name), error: \(errorDict)")
    }
    
    func netServiceWillResolve(_ sender: NetService) {
        print("🔍 NetService will resolve: \(sender.name)")
    }
    
    func netServiceDidResolve(_ sender: NetService) {
        print("🔍 NetService did resolve: \(sender.name)")
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("🔍 NetService did not resolve: \(sender.name), error: \(errorDict)")
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("🔍 NetService did stop: \(sender.name)")
    }
    
    // MARK: - NetServiceBrowserDelegate
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("🔍 NetServiceBrowser will search")
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("🔍 NetServiceBrowser did stop search")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("🔍 NetServiceBrowser did not search: \(errorDict)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("🔍 NetServiceBrowser found service: \(service.name)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("🔍 NetServiceBrowser removed service: \(service.name)")
    }
}

struct PermissionRequestView: View {
    @Binding var showPermissionRequest: Bool
    @State private var localNetworkPermissionGranted = false
    @State private var microphonePermissionGranted = false
    @State private var showingSettings = false
    @StateObject private var permissionManager = PermissionRequestManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("WhisperLAN Needs Permissions")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("To enable peer-to-peer voice messaging, WhisperLAN needs access to your local network and microphone.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Permission Status Cards
                VStack(spacing: 16) {
                    PermissionCard(
                        title: "Local Network Access",
                        description: "Required for discovering nearby devices",
                        icon: "antenna.radiowaves.left.and.right",
                        isGranted: localNetworkPermissionGranted,
                        action: requestLocalNetworkPermission
                    )
                    
                    PermissionCard(
                        title: "Microphone Access",
                        description: "Required for recording voice messages",
                        icon: "mic.fill",
                        isGranted: microphonePermissionGranted,
                        action: requestMicrophonePermission
                    )
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    if localNetworkPermissionGranted && microphonePermissionGranted {
                        Button("Continue to App") {
                            // Mark that we've launched before (permissions granted)
                            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                            showPermissionRequest = false
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    } else {
                        Button("Request All Permissions") {
                            requestAllPermissions()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        
                        Button("Open Settings") {
                            showingSettings = true
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button("Skip for Now") {
                            // Mark that we've launched before (user chose to skip)
                            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                            showPermissionRequest = false
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .onAppear {
                checkPermissions()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsRedirectView()
            }
        }
    }
    
    private func checkPermissions() {
        // Check Local Network permission
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.localNetworkPermissionGranted = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: DispatchQueue.global())
        
        // Check Microphone permission
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphonePermissionGranted = true
        case .denied, .undetermined:
            microphonePermissionGranted = false
        @unknown default:
            microphonePermissionGranted = false
        }
    }
    
    private func requestLocalNetworkPermission() {
        // Use the permission manager to request Local Network permission
        permissionManager.onPermissionRequested = {
            self.checkPermissions()
        }
        permissionManager.requestLocalNetworkPermission()
        
        // Also try a more direct approach with Network framework
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { path in
            print("Network path updated: \(path.status)")
            if path.status == .satisfied {
                print("Network is satisfied - Local Network permission may be granted")
            }
        }
        networkMonitor.start(queue: DispatchQueue.global())
        
        // Stop monitoring after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            networkMonitor.cancel()
        }
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept the invitation to complete the permission request
        invitationHandler(true, nil)
    }
    

    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.microphonePermissionGranted = granted
            }
        }
    }
    
    private func requestAllPermissions() {
        requestLocalNetworkPermission()
        requestMicrophonePermission()
        
        // Re-check permissions after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkPermissions()
        }
    }
}

struct PermissionCard: View {
    let title: String
    let description: String
    let icon: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button("Grant") {
                    action()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SettingsRedirectView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "gear")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Open Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("To grant Local Network and Microphone permissions, please open Settings and enable them for WhisperLAN.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    Button("Back to App") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

 