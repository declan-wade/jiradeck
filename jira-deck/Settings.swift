//
//  Settings.swift
//  JiraDeck
//
//  Created by Declan Wade on 12/9/2024.
//

import Foundation

// Define the settings structure
struct Settings: Codable {
    var projectName: String
    var userName: String
    var apiKey: String
    
    // The path to the settings file in the user's home directory
    static var settingsFilePath: URL {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        print(homeDir)
        return homeDir.appendingPathComponent(".jiradeck_config.json")
    }
    
    // Load settings from the JSON file
    static func load() -> Settings? {
        let path = settingsFilePath
        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            let settings = try decoder.decode(Settings.self, from: data)
            return settings
        } catch {
            print("Failed to load settings: \(error)")
            return nil
        }
    }
    
    // Save settings to the JSON file
    func save() {
        let path = Settings.settingsFilePath
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            try data.write(to: path)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}
