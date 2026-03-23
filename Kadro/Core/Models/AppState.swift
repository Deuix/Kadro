//
//  AppState.swift
//  Kadro
//
//  App-wide state management
//

import Foundation
import SwiftUI

@Observable
final class AppState {
    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    var selectedTab: TabItem = .home
    var showCreateFlow: Bool = false
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Tab Items

enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case create = 1
    case content = 2
    case calendar = 3
    case brand = 4
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .home: return "Главная"
        case .create: return "Создать"
        case .content: return "Контент"
        case .calendar: return "Календарь"
        case .brand: return "Бренд"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .create: return "plus.circle.fill"
        case .content: return "doc.text"
        case .calendar: return "calendar"
        case .brand: return "paintbrush"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .create: return "plus.circle.fill"
        case .content: return "doc.text.fill"
        case .calendar: return "calendar"
        case .brand: return "paintbrush.fill"
        }
    }
}
