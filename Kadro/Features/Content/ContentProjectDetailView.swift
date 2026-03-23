import SwiftUI
import SwiftData

struct ContentProjectDetailView: View {
    let project: ContentProject
    
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BrandProfile]
    
    @State private var isRegenerating = false
    @State private var errorMessage: String?
    @State private var latestResult: GeneratedContentResult?
    
    private let aiService = KadroAIService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                
                if !project.rawInput.isEmpty {
                    textSection(title: "Исходная идея", body: project.rawInput)
                }
                
                if let hook = project.hook, !hook.isEmpty {
                    textSection(title: "Хук", body: hook)
                }
                
                if let mainText = project.mainText, !mainText.isEmpty {
                    textSection(title: project.type == .stories ? "Stories draft" : "Основной текст", body: mainText)
                }
                
                if let cta = project.cta, !cta.isEmpty {
                    textSection(title: "CTA", body: cta)
                }
                
                if let shortVersion = project.shortVersion, !shortVersion.isEmpty {
                    textSection(title: "Короткая версия", body: shortVersion)
                }
                
                if let caption = project.caption, !caption.isEmpty {
                    textSection(title: "Подпись", body: caption)
                }
                
                if let hashtags = project.hashtags, !hashtags.isEmpty {
                    hashtagsSection(hashtags)
                }
                
                if let slides = project.slides, !slides.isEmpty {
                    slidesSection(slides.sorted { $0.order < $1.order })
                }
                
                if let scriptBeats = project.scriptBeats, !scriptBeats.isEmpty {
                    textSection(title: "Сценарные биты", body: scriptBeats)
                }
                
                if let onScreenText = project.onScreenText, !onScreenText.isEmpty {
                    textSection(title: "Текст на экране", body: onScreenText)
                }
                
                if let coverIdea = project.coverIdea, !coverIdea.isEmpty {
                    textSection(title: "Идея обложки", body: coverIdea)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.kadroIvory)
        .navigationTitle(project.title.isEmpty ? "Без названия" : project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Новая версия") {
                    Task {
                        await regenerateProject()
                    }
                }
                .font(.kadroFootnote)
                .foregroundColor(.kadroLime)
                .disabled(isRegenerating)
            }
        }
        .sheet(item: $latestResult) { result in
            GeneratedContentView(result: result)
        }
        .alert(
            "Не удалось создать новую версию",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            ),
            actions: {
                Button("Ок", role: .cancel) {
                    errorMessage = nil
                }
            },
            message: {
                Text(errorMessage ?? "Попробуйте ещё раз.")
            }
        )
        .overlay {
            if isRegenerating {
                ZStack {
                    Color.black.opacity(0.14)
                        .ignoresSafeArea()
                    
                    KadroCard {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.kadroCharcoal)
                            Text("Генерируем новую версию")
                                .font(.kadroTitle3)
                                .foregroundColor(.kadroCharcoal)
                            Text("Создаем новый вариант на основе той же идеи и текущих настроек формата.")
                                .font(.kadroCallout)
                                .foregroundColor(.kadroWarmGray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxWidth: 320)
                    .padding(24)
                }
            }
        }
    }
    
    private var heroCard: some View {
        KadroCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    KadroStatusBadge(title: project.type.rawValue, color: .kadroLime)
                    KadroStatusBadge(title: project.status.rawValue, color: statusColor(for: project.status))
                    Spacer()
                }
                
                Text(project.title.isEmpty ? "Без названия" : project.title)
                    .font(.kadroTitle2)
                    .foregroundColor(.kadroCharcoal)
                
                HStack(spacing: 8) {
                    Text(project.platform.rawValue)
                        .font(.kadroFootnote)
                        .foregroundColor(.kadroWarmGray)
                    
                    if let tone = project.tone {
                        Text("· \(tone.rawValue)")
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                    }
                    
                    if let goal = project.goal {
                        Text("· \(goal.rawValue)")
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                    }
                }
                
                Text(project.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
            }
        }
    }
    
    private func hashtagsSection(_ hashtags: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Хэштеги")
            FlowLayout(spacing: 8) {
                ForEach(hashtags.split(separator: " ").map(String.init), id: \.self) { hashtag in
                    KadroChip(title: hashtag, isSelected: false) {}
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    private func slidesSection(_ slides: [CarouselSlide]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Слайды карусели")
            VStack(spacing: 10) {
                ForEach(slides) { slide in
                    KadroCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Слайд \(slide.order)")
                                .font(.kadroCaption)
                                .foregroundColor(.kadroWarmGray)
                            Text(slide.headline)
                                .font(.kadroTitle3)
                                .foregroundColor(.kadroCharcoal)
                            if !slide.bodyText.isEmpty {
                                Text(slide.bodyText)
                                    .font(.kadroBody)
                                    .foregroundColor(.kadroWarmGray)
                            }
                            if let cta = slide.ctaText, !cta.isEmpty {
                                Text(cta)
                                    .font(.kadroCallout)
                                    .foregroundColor(.kadroCharcoal)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func textSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: title)
            KadroCard {
                Text(body)
                    .font(.kadroBody)
                    .foregroundColor(.kadroCharcoal)
            }
        }
    }
    
    private func statusColor(for status: ContentStatus) -> Color {
        switch status {
        case .draft: return .kadroWarmGray
        case .ready: return .kadroSuccess
        case .scheduled: return .kadroLime
        case .published: return .kadroCharcoal
        }
    }
    
    @MainActor
    private func regenerateProject() async {
        guard !isRegenerating else { return }
        let trimmedInput = project.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            errorMessage = "У проекта нет исходной идеи для повторной генерации."
            return
        }
        
        isRegenerating = true
        errorMessage = nil
        
        let context = KadroGenerationContext(
            inputSource: "Повторная генерация",
            rawInput: trimmedInput,
            outputType: project.type,
            tone: project.tone,
            goal: project.goal,
            platform: project.platform,
            brandProfile: profiles.first
        )
        
        do {
            let payload = try await aiService.generateContent(context: context)
            let newProject = ContentProject.makeFromGeneration(context: context, payload: payload)
            modelContext.insert(newProject)
            try modelContext.save()
            latestResult = GeneratedContentResult(project: newProject, payload: payload)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isRegenerating = false
    }
}

#Preview {
    NavigationStack {
        ContentProjectDetailView(project: ContentProject(title: "Пример", rawInput: "Сырая идея", type: .post, status: .ready, platform: .instagram))
    }
    .environment(AppState())
    .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
