import SwiftUI

struct PeerListView: View {
    @ObservedObject var peerManager: PeerManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Nearby Peers")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    connectionStatusView
                }
                
                // Connection controls
                HStack(spacing: 12) {
                    Button(action: {
                        if peerManager.isHosting {
                            peerManager.stopHosting()
                        } else {
                            peerManager.startHosting()
                        }
                    }) {
                        HStack {
                            Image(systemName: peerManager.isHosting ? "stop.fill" : "antenna.radiowaves.left.and.right")
                            Text(peerManager.isHosting ? "Stop Hosting" : "Start Hosting")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(peerManager.isHosting ? .red : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(peerManager.isHosting ? Color.red.opacity(0.1) : Color.blue)
                        )
                    }
                    
                    Button(action: {
                        if peerManager.isBrowsing {
                            peerManager.stopBrowsing()
                        } else {
                            peerManager.startBrowsing()
                        }
                    }) {
                        HStack {
                            Image(systemName: peerManager.isBrowsing ? "stop.fill" : "magnifyingglass")
                            Text(peerManager.isBrowsing ? "Stop Searching" : "Search")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(peerManager.isBrowsing ? .red : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(peerManager.isBrowsing ? Color.red.opacity(0.1) : Color.green)
                        )
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Peer lists
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Connected peers
                    if !peerManager.connectedPeers.isEmpty {
                        peerSection(title: "Connected", peers: peerManager.connectedPeers, isConnected: true)
                    }
                    
                    // Discovered peers
                    if !peerManager.discoveredPeers.isEmpty {
                        peerSection(title: "Discovered", peers: peerManager.discoveredPeers, isConnected: false)
                    }
                    
                    // Empty state
                    if peerManager.discoveredPeers.isEmpty && peerManager.connectedPeers.isEmpty {
                        emptyStateView
                    }
                }
            }
        }
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch peerManager.connectionStatus {
        case .connected:
            return .green
        case .hosting, .browsing:
            return .orange
        case .disconnected:
            return .red
        }
    }
    
    private var statusText: String {
        switch peerManager.connectionStatus {
        case .connected:
            return "Connected"
        case .hosting:
            return "Hosting"
        case .browsing:
            return "Searching"
        case .disconnected:
            return "Disconnected"
        }
    }
    
    private func peerSection(title: String, peers: [Peer], isConnected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            ForEach(peers) { peer in
                PeerRowView(peer: peer, isConnected: isConnected) {
                    if !isConnected {
                        peerManager.invitePeer(peer)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Peers Found")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Start hosting or searching to discover nearby devices")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

struct PeerRowView: View {
    let peer: Peer
    let isConnected: Bool
    let onInvite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                )
            
            // Peer info
            VStack(alignment: .leading, spacing: 2) {
                Text(peer.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(isConnected ? "Connected" : "Available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                if !isConnected {
                    Button("Connect") {
                        onInvite()
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

#Preview {
    PeerListView(peerManager: PeerManager(encryptionManager: EncryptionManager(), audioManager: AudioManager()))
} 