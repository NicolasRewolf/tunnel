//
//  TunnelApp.swift
//  Tunnel
//
//  Created by Nicolas Doucet on 22/04/2026.
//

import SwiftUI

@main
struct TunnelApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(appState: AppState.shared)
        }
    }
}
