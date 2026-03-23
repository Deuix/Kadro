//
//  HomeView.swift
//  Kadro
//
//  Home tab — personalized dashboard, bento grid actions, recent drafts, stylish ideas
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentProject.updatedAt, order: .reverse) private var projects: [ContentProject]

    // Apparent time of day for greeting
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6: return L10n.Home.greetingNight
        case 6..<12: return L10n.Home.greetingMorning
        case 12..<18: return L10n.Home.greetingAfternoon
        default: return L10n.Home.greetingEvening
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    bentoQuickActions
                    recentDraftsCarousel
                    ideasGallery
                }
                .padding(.bottom, 40)
            }
            .background(Color.kadroBackground(for: colorScheme))
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.custom("New York", size: 24).weight(.medium))
                    .foregroundColor(.kadroSecondary(for: colorScheme))
                
                Text(L10n.Home.creatorBadge)
                    .font(.custom("New York", size: 36).weight(.bold))
                    .foregroundColor(.kadroPrimary(for: colorScheme))
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Bento Quick Actions
    
    private var bentoQuickActions: some View {
        VStack(spacing: 12) {
            // Main Accent Button
            Button {
                appState.openCreate()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(.kadroCharcoal)
                        Spacer()
                        Text(L10n.Home.createContent)
                            .font(.kadroTitle2)
                            .foregroundColor(.kadroCharcoal)
                        Text(L10n.Home.createContentSubtitle)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroCharcoal.opacity(0.7))
                    }
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.kadroCharcoal)
                        .padding(12)
                        .background(Color.white.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 140)
                .background(Color.kadroLime)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .buttonStyle(.plain)
            
            // Secondary row
            HStack(spacing: 12) {
                bentoSecondaryButton(
                    title: L10n.Home.carousel,
                    icon: "rectangle.split.3x1",
                    color: .kadroCharcoal,
                    textColor: .white
                ) {
                    appState.openCreate(outputType: .carousel)
                }

                bentoSecondaryButton(
                    title: L10n.Home.reels,
                    icon: "play.rectangle",
                    color: Color.kadroCard(for: colorScheme),
                    textColor: .kadroPrimary(for: colorScheme)
                ) {
                    appState.openCreate(outputType: .reels)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func bentoSecondaryButton(
        title: String,
        icon: String,
        color: Color,
        textColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Text(title)
                    .font(.kadroBodyMedium)
                    .foregroundColor(textColor)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 110)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(color == .kadroSoftWhite ? Color.kadroSand : Color.clear, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Recent Drafts Carousel
    
    private var recentDraftsCarousel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.Home.drafts)
                    .font(.custom("New York", size: 22).weight(.medium))
                    .foregroundColor(.kadroPrimary(for: colorScheme))

                Spacer()

                Button(L10n.Home.all) {
                    appState.selectedTab = .content
                }
                .font(.kadroFootnote.weight(.medium))
                .foregroundColor(.kadroSecondary(for: colorScheme))
            }
            .padding(.horizontal, 24)
            
            if projects.isEmpty {
                Button {
                    appState.openCreate()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.dashed")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.kadroSecondary(for: colorScheme))
                        Text(L10n.Home.createFirstProject)
                            .font(.kadroCallout)
                            .foregroundColor(.kadroSecondary(for: colorScheme))
                    }
                    .frame(width: 200, height: 260)
                    .background(Color.kadroCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.kadroBorderColor(for: colorScheme), style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(projects.prefix(5)) { project in
                            draftPolaroidCard(for: project)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    private func draftPolaroidCard(for project: ContentProject) -> some View {
        NavigationLink {
            ContentProjectDetailView(project: project)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Card Upper Part - "Photo" area
                Group {
                    if let imageData = project.generatedCoverImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        ZStack {
                            Color.kadroBackground(for: colorScheme)
                            
                            Image(systemName: project.type.icon)
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.kadroSecondary(for: colorScheme).opacity(0.5))
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(8)
                
                // Card Lower Part - Meta
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.title.isEmpty ? L10n.Common.untitled : project.title)
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroPrimary(for: colorScheme))
                        .lineLimit(1)

                    HStack {
                        Text(project.type.displayName)
                            .font(.kadroCaption)
                            .foregroundColor(.kadroSecondary(for: colorScheme))
                        Spacer()
                        Circle()
                            .fill(statusColor(for: project.status))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(width: 200)
            .background(Color.kadroCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Stylish Ideas Gallery
    
    private var ideasGallery: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Home.contentIdeas)
                .font(.custom("New York", size: 22).weight(.medium))
                .foregroundColor(.kadroPrimary(for: colorScheme))
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Dark card — always dark charcoal bg, ivory text — good in both modes
                    editorialIdeaCard(
                        tag: L10n.Home.ideaEducationTag,
                        title: L10n.Home.ideaShareExpertise,
                        color: .kadroCharcoal,
                        textColor: .kadroIvory
                    )

                    // Card that adapts to current surface color
                    editorialIdeaCard(
                        tag: L10n.Home.ideaPersonalTag,
                        title: L10n.Home.ideaPersonalStory,
                        color: Color.kadroCard(for: colorScheme),
                        textColor: .kadroPrimary(for: colorScheme)
                    )

                    editorialIdeaCard(
                        tag: L10n.Home.ideaSalesTag,
                        title: L10n.Home.ideaShowResults,
                        color: .kadroLime.opacity(0.3),
                        textColor: .kadroCharcoal
                    )
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func editorialIdeaCard(tag: String, title: String, color: Color, textColor: Color) -> some View {
        Button {
            appState.openCreate()
        } label: {
            VStack(alignment: .leading) {
                Text(tag.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .default))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.6))
                
                Spacer()
                
                Text(title)
                    .font(.custom("New York", size: 22).weight(.medium))
                    .foregroundColor(textColor)
                    .lineSpacing(4)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor)
                }
            }
            .padding(20)
            .frame(width: 180, height: 220)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(color == .kadroSoftWhite ? Color.kadroSand : Color.clear, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
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
