//
//  KadroApp.swift
//  Kadro
//
//  Created by Atabay on 23.03.2026.
//

import SwiftUI
import SwiftData

@main
struct KadroApp: App {
    @State private var appState = AppState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ContentProject.self,
            CarouselSlide.self,
            BrandProfile.self,
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
            MainTabView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}
