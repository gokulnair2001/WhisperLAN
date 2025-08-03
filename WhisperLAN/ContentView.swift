//
//  ContentView.swift
//  WhisperLAN
//
//  Created by Gokul Nair on 01/08/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var encryptionManager = EncryptionManager()
    @StateObject private var audioManager = AudioManager()
    @StateObject private var peerManager: PeerManager
    @State private var messages: [Message] = []
    @State private var selectedTab = 0
    @State private var selectedPeer: Peer?
    @State private var showingPeerSelection = false
    @State private var lastRecordedMessage: Message?
    
    init() {
        let encryption = EncryptionManager()
        let audio = AudioManager()
        let peer = PeerManager(encryptionManager: encryption, audioManager: audio)
        
        _encryptionManager = StateObject(wrappedValue: encryption)
        _audioManager = StateObject(wrappedValue: audio)
        _peerManager = StateObject(wrappedValue: peer)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Messages Tab
            messagesTab
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Messages")
                }
                .tag(0)
            
            // Peers Tab
            PeerListView(peerManager: peerManager)
                .tabItem {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Peers")
                }
                .tag(1)
            
            // Debug Tab
            DebugView(peerManager: peerManager)
                .tabItem {
                    Image(systemName: "ladybug.fill")
                    Text("Debug")
                }
                .tag(2)
        }
        .onAppear {
            setupMessageHandling()
        }
    }
    
    private var messagesTab: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "message.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Voice Messages")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Connection status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(peerManager.connectedPeers.isEmpty ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text(peerManager.connectedPeers.isEmpty ? "No Peers" : "\(peerManager.connectedPeers.count) Connected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Recording controls
                if !peerManager.connectedPeers.isEmpty {
                    recordingControls
                } else {
                    noPeersView
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Messages list
            if messages.isEmpty {
                emptyMessagesView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(messages) { message in
                            MessageView(
                                message: message,
                                isFromCurrentUser: {
                                    let isFromCurrent = message.senderID == UIDevice.current.name
                                    print("ContentView: Message from \(message.senderName) (ID: \(message.senderID))")
                                    print("ContentView: Current device name: \(UIDevice.current.name)")
                                    print("ContentView: Is from current user: \(isFromCurrent)")
                                    return isFromCurrent
                                }(),
                                audioManager: audioManager
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onAppear {
                    print("ContentView: Messages list appeared with \(messages.count) messages")
                }
            }
        }
    }
    
    private var recordingControls: some View {
        VStack(spacing: 12) {
            // Recording button
            Button(action: {
                if audioManager.isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.title2)
                    
                    Text(audioManager.isRecording ? "Stop Recording" : "Record Message")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(audioManager.isRecording ? Color.red : Color.blue)
                )
            }
            
            // Recording duration
            if audioManager.isRecording {
                Text(formatTime(audioManager.recordingDuration))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }
            
            // Send button (appears after recording)
            if !audioManager.isRecording && lastRecordedMessage != nil {
                Button("Send to All Peers") {
                    sendToAllPeers()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green)
                )
            }
        }
    }
    
    private var noPeersView: some View {
        VStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("No Connected Peers")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Go to Peers tab to discover and connect")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var emptyMessagesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Messages Yet")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Record and send your first voice message")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private func setupMessageHandling() {
        peerManager.onMessageReceived = { message in
            print("ContentView: Received message from \(message.senderName)")
            print("ContentView: Message ID: \(message.id)")
            print("ContentView: Audio data size: \(message.audioData.count) bytes")
            print("ContentView: Current messages count: \(self.messages.count)")
            
            DispatchQueue.main.async {
                self.messages.append(message)
                print("ContentView: Added message to array, new count: \(self.messages.count)")
            }
        }
    }
    
    private func startRecording() {
        // Clear any previous recorded message
        lastRecordedMessage = nil
        audioManager.startRecording()
    }
    
    private func stopRecording() {
        guard let audioData = audioManager.stopRecording() else { return }
        
        let duration = audioManager.getAudioDuration(data: audioData)
        let message = Message(
            senderID: UIDevice.current.name,
            senderName: "Me",
            audioData: audioData,
            duration: duration
        )
        
        // Store the recorded message for sending
        lastRecordedMessage = message
        
        // Add to local messages
        messages.append(message)
    }
    
    private func sendToAllPeers() {
        guard let message = lastRecordedMessage else { return }
        
        for peer in peerManager.connectedPeers {
            peerManager.sendMessage(message, to: peer)
        }
        
        // Clear the recorded message
        lastRecordedMessage = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
