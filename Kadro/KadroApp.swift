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
        
        let storeURL = makeStoreURL()
        
        do {
            let persistentConfig = ModelConfiguration(schema: schema, url: storeURL)
            return try ModelContainer(for: schema, configurations: [persistentConfig])
        } catch {
            print("⚠️ SwiftData persistent store failed to load at \(storeURL.path): \(error)")
            
            do {
                try resetStoreFiles(at: storeURL)
                let resetConfig = ModelConfiguration(schema: schema, url: storeURL)
                let container = try ModelContainer(for: schema, configurations: [resetConfig])
                print("✅ SwiftData store was reset and recreated successfully.")
                return container
            } catch {
                print("⚠️ SwiftData store reset also failed: \(error). Falling back to in-memory store.")
                do {
                    let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    return try ModelContainer(for: schema, configurations: [memoryConfig])
                } catch {
                    fatalError("Could not create in-memory ModelContainer: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Root View (handles onboarding gate)

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.hasCompletedOnboarding {
            MainTabView()
                .transition(.opacity)
        } else {
            OnboardingView()
                .transition(.opacity)
        }
    }
}

// MARK: - SwiftData Store Helpers

private func makeStoreURL() -> URL {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let directory = appSupport.appendingPathComponent("Kadro", isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("Kadro.store")
}

private func resetStoreFiles(at storeURL: URL) throws {
    let fileManager = FileManager.default
    let sidecars = [
        storeURL,
        storeURL.appendingPathExtension("sqlite"),
        URL(fileURLWithPath: storeURL.path + "-shm"),
        URL(fileURLWithPath: storeURL.path + "-wal"),
        URL(fileURLWithPath: storeURL.path + ".sqlite-shm"),
        URL(fileURLWithPath: storeURL.path + ".sqlite-wal")
    ]
    
    for url in sidecars where fileManager.fileExists(atPath: url.path) {
        try fileManager.removeItem(at: url)
    }
}
