//
//  AzFluxEditorApp.swift
//  AzFluxEditor
//
//  Created by Eduardo Fabio Ayaviri Zuna on 10/08/2026.
//

import SwiftUI
import SwiftData

@main
struct AzFluxEditorApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
