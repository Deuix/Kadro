//
//  MainTabView.swift
//  Kadro
//
//  Main tab bar navigation — 5 tabs
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        @Bindable var state = appState
        
        TabView(selection: $state.selectedTab) {
            Tab(TabItem.home.title, systemImage: TabItem.home.icon, value: .home) {
                HomeView()
            }
            
            Tab(TabItem.content.title, systemImage: TabItem.content.icon, value: .content) {
                ContentLibraryView()
            }
            
            Tab(TabItem.create.title, systemImage: TabItem.create.icon, value: .create) {
                CreateFlowView()
            }
            
            Tab(TabItem.calendar.title, systemImage: TabItem.calendar.icon, value: .calendar) {
                CalendarView()
            }
            
            Tab(TabItem.profile.title, systemImage: TabItem.profile.icon, value: .profile) {
                SettingsView()
            }
        }
        .tint(.kadroLime)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
#if canImport(SwiftData)
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
#endif
}
