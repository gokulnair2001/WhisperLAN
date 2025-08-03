import SwiftUI

struct DebugView: View {
    @ObservedObject var peerManager: PeerManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "ladybug.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Debug Console")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Clear") {
                    peerManager.clearDebugMessages()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Button("Reset Network") {
                    peerManager.resetNetworkServices()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Debug messages
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(peerManager.debugMessages.enumerated()), id: \.offset) { index, message in
                        Text(message)
                            .font(.caption)
                            .foregroundColor(message.contains("ERROR") ? .red : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(message.contains("ERROR") ? Color.red.opacity(0.1) : Color(.systemGray6))
                            )
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Status summary
            VStack(spacing: 12) {
                Divider()
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Status:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(statusText)
                            .font(.subheadline)
                            .foregroundColor(statusColor)
                    }
                    
                    HStack {
                        Text("Discovered Peers:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(peerManager.discoveredPeers.count)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Connected Peers:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(peerManager.connectedPeers.count)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
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
}

#Preview {
    DebugView(peerManager: PeerManager(encryptionManager: EncryptionManager(), audioManager: AudioManager()))
} 