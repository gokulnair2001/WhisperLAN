import SwiftUI

struct MessageView: View {
    let message: Message
    let isFromCurrentUser: Bool
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
                messageBubble
            } else {
                messageBubble
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private var messageBubble: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 8) {
            // Debug info
            Text("DEBUG: isFromCurrentUser=\(isFromCurrentUser), sender=\(message.senderName)")
                .font(.caption2)
                .foregroundColor(.red)
                .padding(.horizontal, 4)
            
            // Audio player
            VStack(alignment: .leading, spacing: 8) {
                // Sender name inside the card
                Text(message.senderName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isFromCurrentUser ? .white : .white)
                    .padding(.horizontal, 4)
                
                HStack(spacing: 12) {
                    if !isFromCurrentUser {
                        playButton
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Progress bar
                        ProgressView(value: audioManager.isPlayingMessage(message.id) ? audioManager.playbackProgress : 0, total: message.duration)
                            .progressViewStyle(LinearProgressViewStyle(tint: isFromCurrentUser ? .white : .white))
                            .frame(width: 200, height: 4)
                        
                        // Duration
                        HStack {
                            Text(formatTime(audioManager.isPlayingMessage(message.id) ? audioManager.playbackProgress : 0))
                                .font(.caption2)
                                .foregroundColor(isFromCurrentUser ? .white.opacity(0.8) : .white.opacity(0.8))
                            
                            Spacer()
                            
                            Text(formatTime(message.duration))
                                .font(.caption2)
                                .foregroundColor(isFromCurrentUser ? .white.opacity(0.8) : .white.opacity(0.8))
                        }
                    }
                    
                    if isFromCurrentUser {
                        playButton
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFromCurrentUser ? Color.blue : Color.green)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            
            // Timestamp
            Text(formatTimestamp(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }
    
    private var playButton: some View {
        Button(action: {
            if audioManager.isPlayingMessage(message.id) {
                audioManager.stopPlayback()
            } else {
                audioManager.playAudio(data: message.audioData, messageID: message.id)
            }
        }) {
            Image(systemName: audioManager.isPlayingMessage(message.id) ? "stop.fill" : "play.fill")
                .font(.title2)
                .foregroundColor(isFromCurrentUser ? .white : .white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isFromCurrentUser ? Color.white.opacity(0.3) : Color.white.opacity(0.3))
                )
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        MessageView(
            message: Message(
                senderID: "user1",
                senderName: "John",
                audioData: Data(),
                duration: 30.0
            ),
            isFromCurrentUser: false,
            audioManager: AudioManager()
        )
        
        MessageView(
            message: Message(
                senderID: "user2",
                senderName: "Me",
                audioData: Data(),
                duration: 15.0
            ),
            isFromCurrentUser: true,
            audioManager: AudioManager()
        )
    }
    .padding()
} 