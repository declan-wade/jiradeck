//
//  jira_deckApp.swift
//  jira-deck
//
//  Created by Declan Wade on 9/9/2024.
//

import SwiftUI

@main
struct jira_deckApp: App {
    @State private var projectName = ""
    @State private var userName = ""
    @State private var apiKey = ""

    init() {
        // Load settings when the app launches
        if let loadedSettings = Settings.load() {
            self.projectName = loadedSettings.projectName
            self.userName = loadedSettings.userName
            self.apiKey = loadedSettings.apiKey
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
