import SwiftUI

struct ErrorView: View {
    let error: String
    let action: (() -> Void)?
    
    init(_ error: String, action: (() -> Void)? = nil) {
        self.error = error
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let action = action {
                Button("Try Again") {
                    action()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 8)
        )
    }
}

#Preview {
    ErrorView("Failed to connect to peer. Please try again.") {
        print("Retry action")
    }
} 