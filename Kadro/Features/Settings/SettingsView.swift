//
//  SettingsView.swift
//  Kadro
//
//  Profile tab — user profile, stats, latest content
//

import SwiftUI
import SwiftData
import UserNotifications

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
        return name.isEmpty ? L10n.Home.creatorBadge : name
    }

    private var totalCreated: Int { allProjects.count }
    private var readyOrScheduled: Int {
        allProjects.filter { $0.status == .ready || $0.status == .scheduled }.count
    }
    private var published: Int {
        allProjects.filter { $0.status == .published }.count
    }

    private var posts: [ContentProject]     { allProjects.filter { $0.type == .post } }
    private var carousels: [ContentProject] { allProjects.filter { $0.type == .carousel } }
    private var stories: [ContentProject]   { allProjects.filter { $0.type == .stories } }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    profileHeader
                    latestContentSection
                    statsBento
                    quickActionsBento
                }
                .padding(.bottom, 40)
            }
            .background(Color.kadroBackground(for: colorScheme))
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
            HStack {
                Spacer()
                Button {
                    showSettingsModal = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.kadroPrimary(for: colorScheme))
                        .frame(width: 44, height: 44)
                        .background(Color.kadroCard(for: colorScheme))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 16)

            ZStack {
                Circle()
                    .fill(Color.kadroCharcoal)
                    .frame(width: 100, height: 100)
                Text(String(userName.prefix(1)).uppercased())
                    .font(.custom("New York", size: 48).weight(.medium))
                    .foregroundColor(.kadroIvory)
            }
            .overlay(Circle().stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 1))

            VStack(spacing: 6) {
                Text(userName)
                    .font(.custom("New York", size: 28).weight(.semibold))
                    .foregroundColor(.kadroPrimary(for: colorScheme))

                Button {
                    showSettingsModal = true
                } label: {
                    HStack(spacing: 4) {
                        Text(L10n.Settings.editProfile)
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
                    latestContentCategoryCard(title: ContentType.post.displayName, count: posts.count, projects: posts)
                }
                if !carousels.isEmpty {
                    latestContentCategoryCard(title: ContentType.carousel.displayName, count: carousels.count, projects: carousels)
                }
                if !stories.isEmpty {
                    latestContentCategoryCard(title: ContentType.stories.displayName, count: stories.count, projects: stories)
                }
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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("New York", size: 16).weight(.semibold))
                    .foregroundColor(.white)
                Text(L10n.Settings.worksCount(count))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(12)
        }
        .frame(width: 140, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func emptyContentCard() -> some View {
        Button { appState.openCreate() } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.kadroWarmGray)
                Text(L10n.Common.create)
                    .font(.custom("New York", size: 16).weight(.medium))
                    .foregroundColor(.kadroPrimary(for: colorScheme))
            }
            .frame(width: 140, height: 180)
            .background(Color.kadroCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.kadroBorderColor(for: colorScheme), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Bento

    private var statsBento: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Creator Center")
                .font(.custom("New York", size: 22).weight(.medium))
                .foregroundColor(.kadroPrimary(for: colorScheme))
                .padding(.horizontal, 24)

            HStack(spacing: 12) {
                statCard(value: "\(totalCreated)", title: L10n.Settings.statProjects, subtitle: L10n.Settings.statProjectsSubtitle,
                         color: .kadroCharcoal, textColor: .kadroIvory)
                statCard(value: "\(readyOrScheduled)", title: L10n.Settings.statReady, subtitle: L10n.Settings.statReadySubtitle,
                         color: Color.kadroCard(for: colorScheme), textColor: .kadroPrimary(for: colorScheme))
                statCard(value: "\(published)", title: L10n.Settings.statPublished, subtitle: L10n.Settings.statPublishedSubtitle,
                         color: Color.kadroCard(for: colorScheme), textColor: .kadroPrimary(for: colorScheme))
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
                .stroke(Color.kadroBorderColor(for: colorScheme).opacity(color == .kadroCharcoal ? 0 : 1), lineWidth: 0.5)
        )
    }

    // MARK: - Quick Actions Bento

    private var quickActionsBento: some View {
        HStack(spacing: 12) {
            Button { appState.openCreate() } label: {
                HStack {
                    Image(systemName: "gift")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.kadroPrimary(for: colorScheme))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Settings.quickNewTask)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.kadroPrimary(for: colorScheme))
                        Text(L10n.Settings.quickGenerate)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.kadroWarmGray)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.kadroCard(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Button { appState.selectedTab = .content } label: {
                HStack {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.kadroCharcoal)
                        .padding(8)
                        .background(Color.kadroLime)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Settings.quickIdeas)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.kadroPrimary(for: colorScheme))
                        Text(L10n.Settings.quickLibrary)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.kadroWarmGray)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.kadroCard(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Full Settings Modal

struct ProfileSettingsModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query private var allProjects: [ContentProject]
    @Query private var allProfiles: [BrandProfile]

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showDeleteConfirmation = false
    @State private var showResetConfirmation = false
    @State private var showLanguageSheet = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    appearanceSection
                    notificationsSection
                    languageSection
                    Spacer().frame(height: 12)
                    supportSection
                    Spacer().frame(height: 12)
                    dangerSection
                    versionFooter
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
            .background(Color.kadroBackground(for: colorScheme))
            .navigationTitle(L10n.Settings.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.done) { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.kadroLime)
                }
            }
        }
        .task { await fetchNotificationStatus() }
        .sheet(isPresented: $showLanguageSheet) {
            LanguagePickerSheet()
        }
        .confirmationDialog(
            L10n.Settings.deleteConfirmTitle,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Settings.deleteConfirmAction, role: .destructive) { deleteAllData() }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Settings.deleteConfirmMessage)
        }
        .confirmationDialog(
            L10n.Settings.resetConfirmTitle,
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Settings.resetAction, role: .destructive) {
                appState.hasCompletedOnboarding = false
                dismiss()
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Settings.resetConfirmMessage)
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(L10n.Settings.sectionAppearance)

            HStack(spacing: 10) {
                ForEach(AppTheme.allCases) { theme in
                    themeCard(theme)
                }
            }
            .padding(16)
            .background(Color.kadroCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
            )
        }
    }

    private func themeCard(_ theme: AppTheme) -> some View {
        let isSelected = appState.appTheme == theme
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                appState.appTheme = theme
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? Color.kadroLime : Color.kadroBackground(for: colorScheme))
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? Color.clear : Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
                        )

                    Image(systemName: theme.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? .kadroCharcoal : .kadroWarmGray)
                }

                Text(theme.displayName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .kadroPrimary(for: colorScheme) : .kadroWarmGray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: appState.appTheme)
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(L10n.Settings.notifications)

            settingsCard {
                HStack(spacing: 14) {
                    iconBox("bell.fill", color: .kadroLime, bg: .kadroCharcoal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Settings.pushNotifications)
                            .font(.kadroBodyMedium)
                            .foregroundColor(.kadroPrimary(for: colorScheme))
                        Text(notificationStatusLabel)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                    }
                    Spacer()
                    notificationBadge
                }
                .padding(16)
                .contentShape(Rectangle())
                .onTapGesture { openNotificationSettings() }
            }
        }
    }

    private var notificationStatusLabel: String {
        switch notificationStatus {
        case .authorized:  return L10n.Settings.notificationEnabled
        case .denied:      return L10n.Settings.notificationDenied
        case .provisional: return L10n.Settings.notificationProvisional
        default:           return L10n.Settings.notificationTap
        }
    }

    @ViewBuilder
    private var notificationBadge: some View {
        switch notificationStatus {
        case .authorized:
            Circle().fill(Color.kadroSuccess).frame(width: 10, height: 10)
        case .denied:
            Image(systemName: "arrow.up.right.square")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.kadroWarmGray)
        default:
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.kadroWarmGray)
        }
    }

    // MARK: - Language Section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(L10n.Settings.language)

            settingsCard {
                Button {
                    showLanguageSheet = true
                } label: {
                    HStack(spacing: 14) {
                        iconBox("globe", color: .kadroLime, bg: .kadroCharcoal)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.Settings.appLanguage)
                                .font(.kadroBodyMedium)
                                .foregroundColor(.kadroPrimary(for: colorScheme))
                            Text(currentLanguageLabel)
                                .font(.kadroFootnote)
                                .foregroundColor(.kadroWarmGray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.kadroWarmGray)
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var currentLanguageLabel: String {
        let code = Locale.preferredLanguages.first ?? "ru"
        if code.hasPrefix("ru") { return "Русский 🇷🇺" } // language name, kept as-is
        if code.hasPrefix("en") { return "English 🇬🇧" }
        return Locale.current.localizedString(forLanguageCode: String(code.prefix(2))) ?? code
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(L10n.Settings.sectionSupport)

            settingsCard {
                VStack(spacing: 0) {
                    supportRow(icon: "questionmark.circle.fill", iconBg: Color(red: 0.2, green: 0.5, blue: 1.0),
                                title: L10n.Settings.helpFaq, subtitle: L10n.Settings.helpFaqSubtitle) {}
                    rowDivider()
                    supportRow(icon: "lock.shield.fill", iconBg: Color(red: 0.3, green: 0.7, blue: 0.4),
                                title: L10n.Settings.privacy, subtitle: L10n.Settings.privacySubtitle) {}
                    rowDivider()
                    supportRow(icon: "doc.text.fill", iconBg: Color(red: 0.6, green: 0.4, blue: 0.9),
                                title: L10n.Settings.terms, subtitle: L10n.Settings.termsSubtitle) {}
                    rowDivider()
                    supportRow(icon: "star.fill", iconBg: Color(red: 1.0, green: 0.75, blue: 0.0),
                                title: L10n.Settings.rateApp, subtitle: L10n.Settings.rateAppSubtitle) {}
                    rowDivider()
                    supportRow(icon: "square.and.arrow.up.fill", iconBg: Color.kadroWarmGray,
                                title: L10n.Settings.shareApp, subtitle: L10n.Settings.shareAppSubtitle) {}
                }
            }
        }
    }

    private func supportRow(icon: String, iconBg: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBox(icon, color: .white, bg: iconBg)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroPrimary(for: colorScheme))
                    Text(subtitle)
                        .font(.kadroFootnote)
                        .foregroundColor(.kadroWarmGray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.kadroWarmGray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Danger Zone

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(L10n.Settings.sectionAccount)

            settingsCard {
                VStack(spacing: 0) {
                    Button {
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 14) {
                            iconBox("arrow.counterclockwise", color: .white, bg: Color.kadroWarning)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.Settings.resetOnboarding)
                                    .font(.kadroBodyMedium)
                                    .foregroundColor(.kadroPrimary(for: colorScheme))
                                Text(L10n.Settings.resetOnboardingSubtitle)
                                    .font(.kadroFootnote)
                                    .foregroundColor(.kadroWarmGray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.kadroWarmGray)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    rowDivider()

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 14) {
                            iconBox("trash.fill", color: .white, bg: Color.kadroError)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.Settings.deleteAllTitle)
                                    .font(.kadroBodyMedium)
                                    .foregroundColor(Color.kadroError)
                                Text(L10n.Settings.deleteAllSubtitle)
                                    .font(.kadroFootnote)
                                    .foregroundColor(.kadroWarmGray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.kadroWarmGray)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Version Footer

    private var versionFooter: some View {
        VStack(spacing: 6) {
            Text("Kadro")
                .font(.custom("New York", size: 18).weight(.semibold))
                .foregroundColor(.kadroWarmGray)
            Text(L10n.Settings.versionLabel(appVersion))
                .font(.kadroFootnote)
                .foregroundColor(.kadroWarmGray.opacity(0.6))
            Text(L10n.Settings.madeWithLove)
                .font(.kadroCaption)
                .foregroundColor(.kadroWarmGray.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .foregroundColor(.kadroWarmGray)
            .padding(.leading, 4)
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.kadroCard(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
        )
    }

    private func iconBox(_ icon: String, color: Color, bg: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(color)
            .frame(width: 36, height: 36)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func rowDivider() -> some View {
        Divider()
            .overlay(Color.kadroBorderColor(for: colorScheme))
            .padding(.leading, 66)
    }

    private func fetchNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run { notificationStatus = settings.authorizationStatus }
    }

    private func openNotificationSettings() {
        #if canImport(UIKit)
        if notificationStatus == .notDetermined {
            Task {
                _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                await fetchNotificationStatus()
            }
        } else {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        #endif
    }

    private func deleteAllData() {
        for project in allProjects { modelContext.delete(project) }
        for profile in allProfiles { modelContext.delete(profile) }
        try? modelContext.save()
        appState.hasCompletedOnboarding = false
        dismiss()
    }
}

// MARK: - Language Picker Sheet

struct LanguagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let languages: [(code: String, name: String, flag: String)] = [
        ("ru", "Русский", "🇷🇺"),
        ("en", "English", "🇬🇧"),
    ]

    private var currentCode: String {
        let code = Locale.preferredLanguages.first ?? "ru"
        return String(code.prefix(2))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    infoCard
                    languageList
                    systemSettingsButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
            .background(Color.kadroBackground(for: colorScheme))
            .navigationTitle(L10n.Settings.language)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.done) { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.kadroLime)
                }
            }
        }
    }

    private var infoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.kadroLime)
            Text(L10n.Settings.languageInfo)
                .font(.kadroFootnote)
                .foregroundColor(.kadroWarmGray)
        }
        .padding(16)
        .background(Color.kadroCard(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var languageList: some View {
        VStack(spacing: 0) {
            ForEach(Array(languages.enumerated()), id: \.offset) { index, lang in
                let isSelected = currentCode == lang.code
                HStack(spacing: 14) {
                    Text(lang.flag)
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)
                        .background(Color.kadroBackground(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(lang.name)
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroPrimary(for: colorScheme))

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.kadroLime)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if index < languages.count - 1 {
                    Divider()
                        .overlay(Color.kadroBorderColor(for: colorScheme))
                        .padding(.leading, 74)
                }
            }
        }
        .background(Color.kadroCard(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
        )
    }

    private var systemSettingsButton: some View {
        Button {
            #if canImport(UIKit)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            #endif
        } label: {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .medium))
                Text(L10n.Settings.openIOSSettings)
                    .font(.kadroCallout)
            }
            .foregroundColor(.kadroPrimary(for: colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.kadroCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
            )
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

