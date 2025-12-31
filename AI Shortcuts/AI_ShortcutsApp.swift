//
//  AI_ShortcutsApp.swift
//  AI Shortcuts
//
//  Created by Alex Weichart on 30.12.25.
//

import SwiftUI
import AppIntents

@main
struct AI_ShortcutsApp: App {
    
    init() {
        // Register App Shortcuts with the system
        AIShortcutsProvider.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}
