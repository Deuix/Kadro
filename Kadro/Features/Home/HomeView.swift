//
//  HomeView.swift
//  Kadro
//
//  Home tab — hero CTA, quick actions, recent drafts, AI suggestions
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentProject.updatedAt, order: .reverse) private var projects: [ContentProject]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroCard
                    quickActions
                    recentDrafts
                    ideasForToday
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.kadroIvory)
            .navigationTitle("Главная")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Hero Card
    
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Создайте контент")
                .font(.kadroTitle2)
                .foregroundColor(.kadroSoftWhite)
            
            Text("Превратите идею в пост, карусель или сценарий для Reels.")
                .font(.kadroCallout)
                .foregroundColor(.kadroSoftWhite.opacity(0.8))
            
            Button {
                appState.selectedTab = .create
            } label: {
                Text("Начать")
                    .font(.kadroButton)
                    .foregroundColor(.kadroCharcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.kadroLime)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.kadroCharcoal)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 14) {
            KadroSectionHeader(title: "Быстрое создание")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                KadroQuickActionCard(icon: "text.quote", title: "Пост") {
                    appState.selectedTab = .create
                }
                
                KadroQuickActionCard(icon: "rectangle.split.3x1", title: "Карусель") {
                    appState.selectedTab = .create
                }
                
                KadroQuickActionCard(icon: "video", title: "Reels") {
                    appState.selectedTab = .create
                }
            }
        }
    }
    
    // MARK: - Recent Drafts
    
    private var recentDrafts: some View {
        VStack(alignment: .leading, spacing: 14) {
            KadroSectionHeader(title: "Последние черновики", action: {
                appState.selectedTab = .content
            })
            
            if projects.isEmpty {
                KadroEmptyState(
                    icon: "doc.text.magnifyingglass",
                    title: "Пока пусто",
                    subtitle: "Ваши черновики появятся здесь",
                    buttonTitle: "Создать первый"
                ) {
                    appState.selectedTab = .create
                }
            } else {
                ForEach(projects.prefix(3)) { project in
                    draftCard(for: project)
                }
            }
        }
    }
    
    private func draftCard(for project: ContentProject) -> some View {
        KadroCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: project.type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.kadroLime)
                    .frame(width: 40, height: 40)
                    .background(Color.kadroCharcoal)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title.isEmpty ? "Без названия" : project.title)
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroCharcoal)
                    
                    HStack(spacing: 8) {
                        Text(project.type.rawValue)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                        
                        KadroStatusBadge(
                            title: project.status.rawValue,
                            color: statusColor(for: project.status)
                        )
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Ideas for Today
    
    private var ideasForToday: some View {
        VStack(alignment: .leading, spacing: 14) {
            KadroSectionHeader(title: "Идеи на сегодня")
            
            VStack(spacing: 10) {
                ideaCard(
                    icon: "lightbulb",
                    title: "Обучающий контент",
                    subtitle: "Поделитесь экспертным советом по вашей теме"
                )
                
                ideaCard(
                    icon: "heart",
                    title: "Личная история",
                    subtitle: "Расскажите о своём опыте — это укрепляет доверие"
                )
                
                ideaCard(
                    icon: "bag",
                    title: "Продающий пост",
                    subtitle: "Покажите результат, который получает ваш клиент"
                )
            }
        }
    }
    
    private func ideaCard(icon: String, title: String, subtitle: String) -> some View {
        KadroActionCard(icon: icon, title: title, subtitle: subtitle) {
            appState.selectedTab = .create
        }
    }
    
    // MARK: - Helpers
    
    private func statusColor(for status: ContentStatus) -> Color {
        switch status {
        case .draft: return .kadroWarmGray
        case .ready: return .kadroSuccess
        case .scheduled: return .kadroLime
        case .published: return .kadroCharcoal
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
