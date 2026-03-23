import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private struct PendingGeneratedVisualPreview: Identifiable {
    let target: KadroStyleVisualTarget
    let result: KadroGeneratedStyleImageResponse
    
    var id: String {
        result.id + "-" + target.previewKey
    }
}

private extension KadroStyleVisualTarget {
    var previewKey: String {
        switch self {
        case .cover:
            return "cover"
        case .slide(let id):
            return "slide-\(id.uuidString)"
        }
    }
    
    var useButtonTitle: String {
        switch self {
        case .cover:
            return "Использовать как cover"
        case .slide:
            return "Использовать для слайда"
        }
    }
}

struct ContentProjectDetailView: View {
    let project: ContentProject
    
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BrandProfile]
    
    @State private var isRegenerating = false
    @State private var isGeneratingVisual = false
    @State private var errorMessage: String?
    @State private var latestResult: GeneratedContentResult?
    @State private var generatedVisualPreview: PendingGeneratedVisualPreview?
    @State private var visualLoadingTitle: String = "Генерируем визуал"
    @State private var visualLoadingSubtitle: String = "Собираем reference-guided image generation prompt на основе style pack и ваших референсов."
    
    private let aiService = KadroAIService()
    private let styleImageService = KadroStyleImageService()
    
    private var brandProfile: BrandProfile? {
        profiles.first
    }
    
    private var selectedStylePack: StylePack? {
        if let selected = StylePackLibrary.pack(for: project.selectedStylePackID) {
            return selected
        }
        return StylePackLibrary.pack(for: brandProfile?.selectedStylePackID)
    }
    
    private var selectedStylePackReferenceCount: Int {
        guard let selectedStylePack else { return 0 }
        return StylePackReferenceLoader.referenceCount(for: selectedStylePack.id)
    }
    
    private var sortedSlides: [CarouselSlide] {
        (project.slides ?? []).sorted { $0.order < $1.order }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                visualGenerationCard
                
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
                
                if !sortedSlides.isEmpty {
                    slidesSection(sortedSlides)
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
                .disabled(isRegenerating || isGeneratingVisual)
            }
        }
        .sheet(item: $latestResult) { result in
            GeneratedContentView(result: result)
        }
        .sheet(item: $generatedVisualPreview) { preview in
            GeneratedStyleVisualView(
                result: preview.result,
                useButtonTitle: preview.target.useButtonTitle
            ) {
                applyGeneratedVisual(preview)
            }
        }
        .alert(
            "Что-то пошло не так",
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
            if isRegenerating || isGeneratingVisual {
                loadingOverlay
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
    
    private var visualGenerationCard: some View {
        KadroCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Visual draft")
                    .font(.kadroTitle3)
                    .foregroundColor(.kadroCharcoal)
                
                if let selectedStylePack {
                    Text("Style pack: \(selectedStylePack.displayName)")
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroCharcoal)
                    Text(selectedStylePack.shortDescription)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                    Text("References found: \(selectedStylePackReferenceCount)")
                        .font(.kadroFootnote)
                        .foregroundColor(.kadroWarmGray)
                    Text(selectedStylePack.referenceFolder)
                        .font(.kadroCaption)
                        .foregroundColor(.kadroWarmGray)
                    
                    if let image = platformImage(from: project.generatedCoverImageData) {
                        imageView(image)
                        if let meta = coverMetaText {
                            Text(meta)
                                .font(.kadroCaption)
                                .foregroundColor(.kadroWarmGray)
                        }
                    }
                    
                    Button {
                        Task {
                            await generateCoverVisualDraft()
                        }
                    } label: {
                        Text(project.generatedCoverImageData == nil ? "Создать visual cover" : "Перегенерировать cover")
                            .font(.kadroButton)
                            .foregroundColor(.kadroCharcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.kadroLime)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isGeneratingVisual || selectedStylePackReferenceCount == 0)
                    .opacity((isGeneratingVisual || selectedStylePackReferenceCount == 0) ? 0.55 : 1)
                } else {
                    Text("Сначала выберите style pack в разделе Brand, чтобы мы могли использовать ваши references для visual generation.")
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                }
            }
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.14)
                .ignoresSafeArea()
            
            KadroCard {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.kadroCharcoal)
                    Text(isGeneratingVisual ? visualLoadingTitle : "Генерируем новую версию")
                        .font(.kadroTitle3)
                        .foregroundColor(.kadroCharcoal)
                    Text(isGeneratingVisual ? visualLoadingSubtitle : "Создаем новый вариант на основе той же идеи и текущих настроек формата.")
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
            HStack {
                Text("Слайды карусели")
                    .font(.kadroTitle3)
                    .foregroundColor(.kadroCharcoal)
                Spacer()
                Button("Все visuals") {
                    Task {
                        await generateAllSlideVisuals()
                    }
                }
                .font(.kadroFootnote)
                .foregroundColor(.kadroLime)
                .disabled(isGeneratingVisual || selectedStylePackReferenceCount == 0)
            }
            
            VStack(spacing: 10) {
                ForEach(slides) { slide in
                    KadroCard {
                        VStack(alignment: .leading, spacing: 10) {
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
                            
                            if let image = platformImage(from: slide.generatedImageData) {
                                imageView(image)
                                if let meta = slideMetaText(slide) {
                                    Text(meta)
                                        .font(.kadroCaption)
                                        .foregroundColor(.kadroWarmGray)
                                }
                            }
                            
                            Button {
                                Task {
                                    await generateSlideVisualDraft(slide)
                                }
                            } label: {
                                Text(slide.generatedImageData == nil ? "Создать visual для слайда" : "Перегенерировать visual")
                                    .font(.kadroFootnote)
                                    .foregroundColor(.kadroCharcoal)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.kadroIvory)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(isGeneratingVisual || selectedStylePackReferenceCount == 0)
                            .opacity((isGeneratingVisual || selectedStylePackReferenceCount == 0) ? 0.55 : 1)
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
    
    private var coverMetaText: String? {
        var parts: [String] = []
        if let kind = project.generatedCoverImageVisualKind, !kind.isEmpty {
            parts.append(kind)
        }
        if let pack = project.generatedCoverImageStylePackID, !pack.isEmpty {
            parts.append(pack)
        }
        if let refs = project.generatedCoverImageReferenceFilenames, !refs.isEmpty {
            parts.append(refs)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
    
    private func slideMetaText(_ slide: CarouselSlide) -> String? {
        var parts: [String] = []
        if let kind = slide.generatedImageVisualKind, !kind.isEmpty {
            parts.append(kind)
        }
        if let pack = slide.generatedImageStylePackID, !pack.isEmpty {
            parts.append(pack)
        }
        if let refs = slide.generatedImageReferenceFilenames, !refs.isEmpty {
            parts.append(refs)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
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
    
    @MainActor
    private func generateCoverVisualDraft() async {
        guard !isGeneratingVisual else { return }
        isGeneratingVisual = true
        errorMessage = nil
        visualLoadingTitle = "Генерируем cover"
        visualLoadingSubtitle = "Собираем reference-guided prompt для visual cover на основе style pack и ваших референсов."
        
        do {
            let response = try await styleImageService.generateCoverVisual(project: project, brandProfile: brandProfile)
            generatedVisualPreview = PendingGeneratedVisualPreview(target: .cover, result: response)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGeneratingVisual = false
    }
    
    @MainActor
    private func generateSlideVisualDraft(_ slide: CarouselSlide) async {
        guard !isGeneratingVisual else { return }
        isGeneratingVisual = true
        errorMessage = nil
        visualLoadingTitle = "Генерируем visual для слайда"
        visualLoadingSubtitle = "Слайд \(slide.order): формируем visual по headline/body и выбранному style pack."
        
        do {
            let response = try await styleImageService.generateSlideVisual(project: project, slide: slide, brandProfile: brandProfile)
            generatedVisualPreview = PendingGeneratedVisualPreview(target: .slide(slide.id), result: response)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGeneratingVisual = false
    }
    
    @MainActor
    private func generateAllSlideVisuals() async {
        guard !isGeneratingVisual else { return }
        let slides = sortedSlides
        guard !slides.isEmpty else { return }
        
        isGeneratingVisual = true
        errorMessage = nil
        
        for (index, slide) in slides.enumerated() {
            visualLoadingTitle = "Генерируем visuals для карусели"
            visualLoadingSubtitle = "Слайд \(index + 1) из \(slides.count): \(slide.headline)"
            
            do {
                let response = try await styleImageService.generateSlideVisual(project: project, slide: slide, brandProfile: brandProfile)
                try persistGeneratedVisual(response, target: .slide(slide.id))
            } catch {
                errorMessage = "Ошибка на слайде \(slide.order): \(error.localizedDescription)"
                break
            }
        }
        
        isGeneratingVisual = false
    }
    
    @MainActor
    private func applyGeneratedVisual(_ preview: PendingGeneratedVisualPreview) {
        do {
            try persistGeneratedVisual(preview.result, target: preview.target)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func persistGeneratedVisual(_ result: KadroGeneratedStyleImageResponse, target: KadroStyleVisualTarget) throws {
        guard let imageData = styleImageService.imageData(from: result.imageDataURL) else {
            throw NSError(domain: "KadroStyleImageService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось сохранить сгенерированный визуал."])
        }
        
        switch target {
        case .cover:
            project.generatedCoverImageData = imageData
            project.generatedCoverImagePrompt = result.promptUsed
            project.generatedCoverImageModel = result.model
            project.generatedCoverImageStylePackID = result.stylePackID
            project.generatedCoverImageReferenceFilenames = result.referenceFilenames.joined(separator: ", ")
            project.generatedCoverImageVisualKind = result.visualKind
            project.generatedCoverImageUpdatedAt = Date()
        case .slide(let slideID):
            guard let slide = project.slides?.first(where: { $0.id == slideID }) else {
                throw NSError(domain: "KadroStyleImageService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Не удалось найти слайд для сохранения визуала."])
            }
            slide.generatedImageData = imageData
            slide.generatedImagePrompt = result.promptUsed
            slide.generatedImageModel = result.model
            slide.generatedImageStylePackID = result.stylePackID
            slide.generatedImageReferenceFilenames = result.referenceFilenames.joined(separator: ", ")
            slide.generatedImageVisualKind = result.visualKind
            slide.generatedImageUpdatedAt = Date()
        }
        
        project.updatedAt = Date()
        try modelContext.save()
    }
    
    #if canImport(UIKit)
    private func platformImage(from data: Data?) -> UIImage? {
        guard let data else { return nil }
        return UIImage(data: data)
    }
    
    private func imageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.kadroSand, lineWidth: 1)
            )
    }
    #elseif canImport(AppKit)
    private func platformImage(from data: Data?) -> NSImage? {
        guard let data else { return nil }
        return NSImage(data: data)
    }
    
    private func imageView(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.kadroSand, lineWidth: 1)
            )
    }
    #endif
}

#Preview {
    NavigationStack {
        ContentProjectDetailView(project: ContentProject(title: "Пример", rawInput: "Сырая идея", type: .post, status: .ready, platform: .instagram))
    }
    .environment(AppState())
    .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
