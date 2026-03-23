//
//  AppState.swift
//  Kadro
//
//  App-wide state management
//

import Foundation
import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return L10n.Theme.system
        case .light:  return L10n.Theme.light
        case .dark:   return L10n.Theme.dark
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max"
        case .dark:   return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

@Observable
final class AppState {
    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: "appTheme")
        }
    }
    
    var selectedTab: TabItem = .home
    var showCreateFlow: Bool = false
    var createDraft: CreateDraft?
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue
        self.appTheme = AppTheme(rawValue: savedTheme) ?? .system
    }
    
    func openCreate(
        outputType: ContentType? = nil,
        source: InputSource? = nil,
        seedText: String = ""
    ) {
        createDraft = CreateDraft(
            outputType: outputType,
            source: source,
            seedText: seedText
        )
        selectedTab = .create
    }
    
    func consumeCreateDraft() -> CreateDraft? {
        defer { createDraft = nil }
        return createDraft
    }
}

struct CreateDraft {
    let outputType: ContentType?
    let source: InputSource?
    let seedText: String
}

// MARK: - Tab Items

enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case create = 1
    case content = 2
    case calendar = 3
    case profile = 4
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .home: return L10n.Tab.home
        case .create: return L10n.Tab.create
        case .content: return L10n.Tab.content
        case .calendar: return L10n.Tab.calendar
        case .profile: return L10n.Tab.profile
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .create: return "plus.circle.fill"
        case .content: return "doc.text"
        case .calendar: return "calendar"
        case .profile: return "person.crop.circle"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .create: return "plus.circle.fill"
        case .content: return "doc.text.fill"
        case .calendar: return "calendar"
        case .profile: return "person.crop.circle.fill"
        }
    }
}
