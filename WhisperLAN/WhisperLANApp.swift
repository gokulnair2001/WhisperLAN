//
//  WhisperLANApp.swift
//  WhisperLAN
//
//  Created by Gokul Nair on 01/08/25.
//

import SwiftUI
import AVFoundation

@main
struct WhisperLANApp: App {
    @State private var showingLaunchScreen = true
    @State private var showingPermissionRequest = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showingLaunchScreen || showingPermissionRequest ? 0 : 1)

                if showingLaunchScreen {
                    LaunchScreen()
                        .transition(.opacity)
                }
                
                if showingPermissionRequest {
                    PermissionRequestView(showPermissionRequest: $showingPermissionRequest)
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Show launch screen for 2 seconds, then check permissions
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingLaunchScreen = false
                        checkAndShowPermissions()
                    }
                }
            }
        }
    }
    
    private func checkAndShowPermissions() {
        // Check if we need to show permission request
        let needsMicrophone = !hasMicrophonePermission()
        
        // For Local Network, we'll only show the permission screen if microphone is also needed
        // or if this is the first launch (we can't reliably check Local Network permission)
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        
        if needsMicrophone || isFirstLaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showingPermissionRequest = true
                }
            }
        } else {
            // Mark that we've launched before
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    private func hasLocalNetworkPermission() -> Bool {
        // Local Network permission is difficult to check reliably
        // We'll assume it's granted if the app has been used before
        return UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    }
    
    private func hasMicrophonePermission() -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied, .undetermined:
            return false
        @unknown default:
            return false
        }
    }
}
