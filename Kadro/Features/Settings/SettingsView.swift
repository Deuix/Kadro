//
//  SettingsView.swift
//  Kadro
//
//  Profile screen — user profile, stats, latest content
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BrandProfile]
    @Query(sort: \ContentProject.updatedAt, order: .reverse) private var allProjects: [ContentProject]
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSettingsModal = false
    
    private var profile: BrandProfile? { profiles.first }
    
    private var userName: String {
        let name = profile?.brandName ?? ""
        return name.isEmpty ? "Криэйтор ✦" : name
    }
    
    // Example stats calculations
    private var totalCreated: Int {
        allProjects.count
    }
    
    private var readyOrScheduled: Int {
        allProjects.filter { $0.status == .ready || $0.status == .scheduled }.count
    }
    
    private var publishedPoints: Int {
        allProjects.filter { $0.status == .published }.count
    }
    
    // Categories for latest content
    private var posts: [ContentProject] { allProjects.filter { $0.type == .post } }
    private var carousels: [ContentProject] { allProjects.filter { $0.type == .carousel } }
    private var stories: [ContentProject] { allProjects.filter { $0.type == .stories } }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // 1. Header with Avatar & Name
                    profileHeader

                    // 2. Latest content horizontally
                    latestContentSection

                    // 3. Stats Bento
                    statsBento

                    // 4. Quick Actions / Rewards
                    quickActionsBento

                }
                .padding(.bottom, 40)
            }
            .background(Color.kadroIvory)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSettingsModal) {
            ProfileSettingsModal()
                .environment(appState)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Settings Button top right
            HStack {
                Spacer()
                Button {
                    showSettingsModal = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.kadroCharcoal)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 16)
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.kadroCharcoal)
                    .frame(width: 100, height: 100)
                
                Text(String(userName.prefix(1)).uppercased())
                    .font(.custom("New York", size: 48).weight(.medium))
                    .foregroundColor(.kadroIvory)
            }
            .overlay(
                Circle().stroke(Color.kadroSand, lineWidth: 1)
            )
            
            // Info
            VStack(spacing: 6) {
                Text(userName)
                    .font(.custom("New York", size: 28).weight(.semibold))
                    .foregroundColor(.kadroCharcoal)
                
                Button {
                    appState.selectedTab = .home // Or open edit profile
                } label: {
                    HStack(spacing: 4) {
                        Text("Мой профиль")
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.kadroWarmGray)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Latest Content Section
    
    private var latestContentSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if !posts.isEmpty {
                    latestContentCategoryCard(title: "Посты", count: posts.count, projects: posts)
                }
                if !carousels.isEmpty {
                    latestContentCategoryCard(title: "Карусели", count: carousels.count, projects: carousels)
                }
                if !stories.isEmpty {
                    latestContentCategoryCard(title: "Истории", count: stories.count, projects: stories)
                }
                
                // If everything is empty
                if posts.isEmpty && carousels.isEmpty && stories.isEmpty {
                    emptyContentCard()
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func latestContentCategoryCard(title: String, count: Int, projects: [ContentProject]) -> some View {
        let latestProject = projects.first!
        
        return ZStack(alignment: .bottomLeading) {
            // Background / Image
            if let imageData = latestProject.generatedCoverImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 180)
                    .clipped()
                    .overlay(Color.black.opacity(0.2))
            } else {
                Color.kadroCharcoal
                    .frame(width: 140, height: 180)
                    .overlay(
                        Image(systemName: latestProject.type.icon)
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundColor(.white.opacity(0.1))
                    )
            }
            
            // Overlay content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("New York", size: 16).weight(.semibold))
                    .foregroundColor(.white)
                Text("\(count) работ")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(12)
        }
        .frame(width: 140, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func emptyContentCard() -> some View {
        Button {
            appState.openCreate()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.kadroWarmGray)
                Text("Создать")
                    .font(.custom("New York", size: 16).weight(.medium))
                    .foregroundColor(.kadroCharcoal)
            }
            .frame(width: 140, height: 180)
            .background(Color.kadroSoftWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.kadroSand, style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Stats Bento
    
    private var statsBento: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Creator Center")
                .font(.custom("New York", size: 22).weight(.medium))
                .foregroundColor(.kadroCharcoal)
                .padding(.horizontal, 24)
            
            HStack(spacing: 12) {
                statCard(value: "\(totalCreated)", title: "Проектов", subtitle: "создано", color: .kadroCharcoal, textColor: .kadroIvory)
                statCard(value: "\(readyOrScheduled)", title: "Готовы", subtitle: "к публикации", color: .kadroSoftWhite, textColor: .kadroCharcoal)
                statCard(value: "⭐️", title: "Баланс", subtitle: "кармы", color: .kadroSoftWhite, textColor: .kadroCharcoal)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func statCard(value: String, title: String, subtitle: String, color: Color, textColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("New York", size: 26).weight(.bold))
                .foregroundColor(textColor)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textColor)
            Text(subtitle)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(textColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(color == .kadroSoftWhite ? Color.kadroSand : Color.clear, lineWidth: 0.5)
        )
    }
    
    // MARK: - Quick Actions Bento
    
    private var quickActionsBento: some View {
        HStack(spacing: 12) {
            // Task Card
            Button {
                appState.openCreate()
            } label: {
                HStack {
                    Image(systemName: "gift")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.kadroCharcoal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Новый таск")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.kadroCharcoal)
                        Text("Генерация")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.kadroWarmGray)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.kadroSoftWhite)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.kadroSand, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            
            // Inspiration
            Button {
                appState.selectedTab = .content
            } label: {
                HStack {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.kadroCharcoal)
                        .padding(8)
                        .background(Color.kadroLime)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Идеи")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.kadroCharcoal)
                        Text("Библиотека")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.kadroWarmGray)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.kadroSoftWhite)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.kadroSand, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Modal Settings View
struct ProfileSettingsModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    menuRow(icon: "star", title: "Подписка Kadro Pro", isDivider: false) {}
                    Divider().padding(.leading, 64).overlay(Color.kadroSand.opacity(0.3))
                    menuRow(icon: "paintbrush", title: "Оформление (Тема)", isDivider: false) {}
                    Divider().padding(.leading, 64).overlay(Color.kadroSand.opacity(0.3))
                    menuRow(icon: "bell", title: "Уведомления", isDivider: false) {}
                    Divider().padding(.leading, 64).overlay(Color.kadroSand.opacity(0.3))
                    menuRow(icon: "questionmark.circle", title: "Помощь и FAQ", isDivider: false) {}
                }
                .background(Color.kadroSoftWhite)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.kadroSand, lineWidth: 0.5))
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Button {
                    showResetConfirmation = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.kadroError)
                            .frame(width: 24)
                        
                        Text("Сбросить аккаунт")
                            .font(.custom("New York", size: 18).weight(.medium))
                            .foregroundColor(.kadroError)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(Color.kadroSoftWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.kadroError.opacity(0.3), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .background(Color.kadroIvory)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.kadroCharcoal)
                }
            }
            .confirmationDialog(
                "Сбросить онбординг?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Сбросить", role: .destructive) {
                    appState.hasCompletedOnboarding = false
                    dismiss()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Вы увидите экран приветствия при следующем запуске.")
            }
        }
    }
    
    private func menuRow(icon: String, title: String, isDivider: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.kadroCharcoal)
                    .frame(width: 24)
                
                Text(title)
                    .font(.custom("New York", size: 18).weight(.medium))
                    .foregroundColor(.kadroCharcoal)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.kadroWarmGray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
#if canImport(SwiftData)
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
#endif
}
