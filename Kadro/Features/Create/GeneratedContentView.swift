import SwiftUI
import SwiftData

private struct GeneratedPreviewVisual: Identifiable {
    let target: KadroStyleVisualTarget
    let result: KadroGeneratedStyleImageResponse
    
    var id: String {
        let key: String
        switch target {
        case .cover: key = "cover"
        case .slide(let id): key = "slide-\(id.uuidString)"
        }
        return result.id + "-preview-" + key
    }
}

private struct VisualPromptRequest: Identifiable {
    let target: KadroStyleVisualTarget
    let title: String
    
    var id: String {
        switch target {
        case .cover: return "cover"
        case .slide(let id): return "slide-\(id.uuidString)"
        }
    }
}

private extension KadroStyleVisualTarget {
    var generatedButtonTitle: String {
        switch self {
        case .cover: return "Использовать как cover"
        case .slide: return "Использовать для слайда"
        }
    }
}

struct GeneratedContentView: View {
    let result: GeneratedContentResult
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BrandProfile]
    
    @State private var isGeneratingVisual = false
    @State private var visualErrorMessage: String?
    @State private var generatedVisualPreview: GeneratedPreviewVisual?
    @State private var visualPromptRequest: VisualPromptRequest?
    @State private var visualPromptText: String = ""
    @State private var visualLoadingTitle: String = "Генерируем визуалы"
    @State private var visualLoadingSubtitle: String = "Собираем reference-guided image generation prompt."
    
    private let styleImageService = KadroStyleImageService()
    
    private var project: ContentProject { result.project }
    private var slides: [CarouselSlide] { (project.slides ?? []).sorted { $0.order < $1.order } }
    private var brandProfile: BrandProfile? { profiles.first }
    private var selectedStylePack: StylePack? { StylePackLibrary.pack(for: project.selectedStylePackID) }
    private var selectedStylePackReferenceCount: Int {
        guard let selectedStylePack else { return 0 }
        return StylePackReferenceLoader.referenceCount(for: selectedStylePack.id)
    }
    private var generatedSlidePreviewAssets: [KadroPreviewImageAsset] {
        slides.compactMap(slidePreviewAsset(for:))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    visualPreviewSection
                    
                    if !result.payload.hook.isEmpty { textSection(title: "Хук", body: result.payload.hook) }
                    if !result.payload.mainText.isEmpty { textSection(title: "Основной текст", body: result.payload.mainText) }
                    if !result.payload.cta.isEmpty { textSection(title: "CTA", body: result.payload.cta) }
                    if !result.payload.shortVersion.isEmpty { textSection(title: "Короткая версия", body: result.payload.shortVersion) }
                    if !result.payload.caption.isEmpty { textSection(title: "Подпись", body: result.payload.caption) }
                    if !result.payload.hashtags.isEmpty { tagSection }
                    if !result.payload.carousel.slides.isEmpty { carouselSection }
                    if !result.payload.reels.scriptBeats.isEmpty || !result.payload.reels.onScreenText.isEmpty || !result.payload.reels.coverIdea.isEmpty { reelsSection }
                    if !result.payload.stories.isEmpty { storiesSection }
                    if !result.payload.variants.isEmpty { variantsSection }
                    if !result.payload.suggestedNextActions.isEmpty { nextActionsSection }
                    metadataSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.kadroIvory)
            .navigationTitle("Готово")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(.kadroLime)
                }
            }
            .sheet(item: $generatedVisualPreview) { preview in
                GeneratedStyleVisualView(result: preview.result, useButtonTitle: preview.target.generatedButtonTitle) {
                    applyGeneratedVisual(preview)
                }
            }
            .sheet(item: $visualPromptRequest) { request in
                VisualPromptInputSheet(title: request.title, promptText: $visualPromptText) {
                    Task {
                        await handlePromptGeneration(request)
                    }
                }
            }
            .alert(
                "Не удалось создать визуал",
                isPresented: Binding(get: { visualErrorMessage != nil }, set: { if !$0 { visualErrorMessage = nil } }),
                actions: { Button("Ок", role: .cancel) { visualErrorMessage = nil } },
                message: { Text(visualErrorMessage ?? "Попробуйте ещё раз.") }
            )
            .overlay {
                if isGeneratingVisual {
                    ZStack {
                        Color.black.opacity(0.14).ignoresSafeArea()
                        KadroCard {
                            VStack(spacing: 12) {
                                ProgressView().tint(.kadroCharcoal)
                                Text(visualLoadingTitle).font(.kadroTitle3).foregroundColor(.kadroCharcoal)
                                Text(visualLoadingSubtitle).font(.kadroCallout).foregroundColor(.kadroWarmGray).multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxWidth: 320)
                        .padding(24)
                    }
                }
            }
        }
    }
    
    private var heroCard: some View {
        KadroCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    KadroStatusBadge(title: result.project.type.rawValue, color: .kadroLime)
                    Spacer()
                    Text("Сохранено в Контент").font(.kadroCaption).foregroundColor(.kadroWarmGray)
                }
                Text(result.payload.title).font(.kadroTitle2).foregroundColor(.kadroCharcoal)
                if !result.payload.summary.isEmpty {
                    Text(result.payload.summary).font(.kadroBody).foregroundColor(.kadroWarmGray)
                }
            }
        }
    }
    
    private var visualPreviewSection: some View {
        KadroCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Visual preview").font(.kadroTitle3).foregroundColor(.kadroCharcoal)
                
                if let selectedStylePack {
                    Text("Style pack: \(selectedStylePack.displayName)").font(.kadroBodyMedium).foregroundColor(.kadroCharcoal)
                    Text("References found: \(selectedStylePackReferenceCount)").font(.kadroFootnote).foregroundColor(.kadroWarmGray)
                    
                    if let coverPreviewAsset {
                        KadroPreviewableGeneratedImage(asset: coverPreviewAsset)
                    }
                    
                    HStack(spacing: 10) {
                        actionButton(title: project.generatedCoverImageData == nil ? "Создать cover" : "Перегенерировать cover") {
                            visualPromptText = project.generatedCoverImagePrompt ?? ""
                            visualPromptRequest = VisualPromptRequest(target: .cover, title: project.generatedCoverImageData == nil ? "Создать cover" : "Перегенерировать cover")
                        }
                        
                        if !slides.isEmpty {
                            actionButton(title: "Все visuals") {
                                Task { await generateAllSlideVisuals() }
                            }
                        }
                    }
                } else {
                    Text("Style pack не выбран. Выберите стиль на этапе создания контента.").font(.kadroCallout).foregroundColor(.kadroWarmGray)
                }
            }
        }
    }
    
    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Хэштеги")
            FlowLayout(spacing: 8) {
                ForEach(result.payload.hashtags, id: \.self) { hashtag in
                    KadroChip(title: hashtag, isSelected: false) {}.allowsHitTesting(false)
                }
            }
        }
    }
    
    private var carouselSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Слайды карусели")
                    .font(.kadroTitle3)
                    .foregroundColor(.kadroCharcoal)
                Spacer()
                if !generatedSlidePreviewAssets.isEmpty {
                    KadroDownloadGeneratedImagesButton(assets: generatedSlidePreviewAssets, isDisabled: isGeneratingVisual) { isDownloading in
                        Text(isDownloading ? "Сохраняем..." : "Скачать все")
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroLime)
                    }
                }
            }
            VStack(spacing: 10) {
                ForEach(slides) { slide in
                    KadroCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Слайд \(slide.order)").font(.kadroCaption).foregroundColor(.kadroWarmGray)
                            Text(slide.headline).font(.kadroTitle3).foregroundColor(.kadroCharcoal)
                            Text(slide.bodyText).font(.kadroBody).foregroundColor(.kadroWarmGray)
                            if let cta = slide.ctaText, !cta.isEmpty { Text(cta).font(.kadroCallout).foregroundColor(.kadroCharcoal) }
                            if let asset = slidePreviewAsset(for: slide) {
                                KadroPreviewableGeneratedImage(asset: asset)
                            }
                            actionButton(title: slide.generatedImageData == nil ? "Создать visual для слайда" : "Перегенерировать visual") {
                                visualPromptText = slide.generatedImagePrompt ?? ""
                                visualPromptRequest = VisualPromptRequest(target: .slide(slide.id), title: slide.generatedImageData == nil ? "Создать visual для слайда" : "Перегенерировать visual")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var reelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Reels / TikTok")
            if !result.payload.reels.hook.isEmpty { textSection(title: "Reels hook", body: result.payload.reels.hook) }
            if !result.payload.reels.scriptBeats.isEmpty { bulletSection(title: "Сценарные биты", items: result.payload.reels.scriptBeats) }
            if !result.payload.reels.onScreenText.isEmpty { bulletSection(title: "Текст на экране", items: result.payload.reels.onScreenText) }
            if !result.payload.reels.coverIdea.isEmpty { textSection(title: "Идея обложки", body: result.payload.reels.coverIdea) }
        }
    }
    
    private var storiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Stories")
            VStack(spacing: 10) {
                ForEach(Array(result.payload.stories.enumerated()), id: \.offset) { index, frame in
                    KadroCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Сторис \(index + 1)").font(.kadroCaption).foregroundColor(.kadroWarmGray)
                            Text(frame.title).font(.kadroTitle3).foregroundColor(.kadroCharcoal)
                            Text(frame.body).font(.kadroBody).foregroundColor(.kadroWarmGray)
                            if !frame.stickerIdea.isEmpty { Text("Стикер: \(frame.stickerIdea)").font(.kadroCallout).foregroundColor(.kadroCharcoal) }
                        }
                    }
                }
            }
        }
    }
    
    private var variantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Варианты")
            VStack(spacing: 10) {
                ForEach(result.payload.variants) { variant in
                    KadroCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(variant.label).font(.kadroFootnote).foregroundColor(.kadroWarmGray)
                            Text(variant.text).font(.kadroBody).foregroundColor(.kadroCharcoal)
                        }
                    }
                }
            }
        }
    }
    
    private var nextActionsSection: some View {
        bulletSection(title: "Что можно сделать дальше", items: result.payload.suggestedNextActions)
    }
    
    private var metadataSection: some View {
        KadroCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI metadata").font(.kadroFootnote).foregroundColor(.kadroWarmGray)
                Text("Text: \(result.payload.metadata.textModel)").font(.kadroCaption).foregroundColor(.kadroWarmGray)
                Text("Cheap ops: \(result.payload.metadata.cheapModel)").font(.kadroCaption).foregroundColor(.kadroWarmGray)
                Text("Image: \(result.payload.metadata.imageModel)").font(.kadroCaption).foregroundColor(.kadroWarmGray)
                Text("Candidate: \(result.payload.metadata.candidateModel)").font(.kadroCaption).foregroundColor(.kadroWarmGray)
                if result.payload.metadata.fallbackUsed == true {
                    Text("Fallback: активирован").font(.kadroCaption).foregroundColor(.kadroWarning)
                    if let reason = result.payload.metadata.fallbackReason, !reason.isEmpty {
                        Text(reason).font(.kadroCaption).foregroundColor(.kadroWarmGray)
                    }
                }
            }
        }
    }
    
    private func textSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: title)
            KadroCard { Text(body).font(.kadroBody).foregroundColor(.kadroCharcoal) }
        }
    }
    
    private func bulletSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: title)
            KadroCard {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Color.kadroLime).frame(width: 6, height: 6).padding(.top, 7)
                            Text(item).font(.kadroBody).foregroundColor(.kadroCharcoal)
                        }
                    }
                }
            }
        }
    }
    
    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
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
    
    @MainActor
    private func handlePromptGeneration(_ request: VisualPromptRequest) async {
        switch request.target {
        case .cover:
            await generateCoverVisual(promptOverride: visualPromptText)
        case .slide(let id):
            guard let slide = slides.first(where: { $0.id == id }) else { return }
            await generateSlideVisual(slide, promptOverride: visualPromptText)
        }
    }
    
    @MainActor
    private func generateCoverVisual(promptOverride: String? = nil) async {
        guard !isGeneratingVisual else { return }
        isGeneratingVisual = true
        visualLoadingTitle = "Генерируем cover"
        visualLoadingSubtitle = "Собираем reference-guided prompt для visual cover на основе style pack и ваших референсов."
        
        do {
            let response = try await styleImageService.generateCoverVisual(project: project, brandProfile: brandProfile, promptOverride: promptOverride)
            generatedVisualPreview = GeneratedPreviewVisual(target: .cover, result: response)
        } catch {
            visualErrorMessage = error.localizedDescription
        }
        
        isGeneratingVisual = false
    }
    
    @MainActor
    private func generateSlideVisual(_ slide: CarouselSlide, promptOverride: String? = nil) async {
        guard !isGeneratingVisual else { return }
        isGeneratingVisual = true
        visualLoadingTitle = "Генерируем visual для слайда"
        visualLoadingSubtitle = "Слайд \(slide.order): формируем visual по headline/body и выбранному style pack."
        
        do {
            let response = try await styleImageService.generateSlideVisual(project: project, slide: slide, brandProfile: brandProfile, promptOverride: promptOverride)
            generatedVisualPreview = GeneratedPreviewVisual(target: .slide(slide.id), result: response)
        } catch {
            visualErrorMessage = error.localizedDescription
        }
        
        isGeneratingVisual = false
    }
    
    @MainActor
    private func generateAllSlideVisuals() async {
        guard !isGeneratingVisual else { return }
        isGeneratingVisual = true
        
        for (index, slide) in slides.enumerated() {
            visualLoadingTitle = "Генерируем visuals для карусели"
            visualLoadingSubtitle = "Слайд \(index + 1) из \(slides.count): \(slide.headline)"
            
            do {
                let response = try await styleImageService.generateSlideVisual(project: project, slide: slide, brandProfile: brandProfile)
                try persistGeneratedVisual(response, target: .slide(slide.id))
            } catch {
                visualErrorMessage = "Ошибка на слайде \(slide.order): \(error.localizedDescription)"
                break
            }
        }
        
        isGeneratingVisual = false
    }
    
    @MainActor
    private func applyGeneratedVisual(_ preview: GeneratedPreviewVisual) {
        do { try persistGeneratedVisual(preview.result, target: preview.target) }
        catch { visualErrorMessage = error.localizedDescription }
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
    
    private var coverPreviewAsset: KadroPreviewImageAsset? {
        guard let data = project.generatedCoverImageData else { return nil }
        return KadroPreviewImageAsset(
            id: "generated-cover-\(project.id.uuidString)",
            title: project.title.isEmpty ? "Cover" : project.title,
            subtitle: previewSubtitle(
                visualKind: project.generatedCoverImageVisualKind,
                stylePackID: project.generatedCoverImageStylePackID,
                references: project.generatedCoverImageReferenceFilenames
            ),
            filenameStem: "kadro-\(project.title.isEmpty ? "cover" : project.title)-cover",
            imageData: data
        )
    }
    
    private func slidePreviewAsset(for slide: CarouselSlide) -> KadroPreviewImageAsset? {
        guard let data = slide.generatedImageData else { return nil }
        return KadroPreviewImageAsset(
            id: "generated-slide-\(slide.id.uuidString)",
            title: "Слайд \(slide.order)",
            subtitle: previewSubtitle(
                visualKind: slide.generatedImageVisualKind,
                stylePackID: slide.generatedImageStylePackID,
                references: slide.generatedImageReferenceFilenames
            ),
            filenameStem: "kadro-\(project.title.isEmpty ? "carousel" : project.title)-slide-\(slide.order)",
            imageData: data
        )
    }
    
    private func previewSubtitle(visualKind: String?, stylePackID: String?, references: String?) -> String? {
        var parts: [String] = []
        if let visualKind, !visualKind.isEmpty {
            parts.append(visualKind)
        }
        if let stylePackID, !stylePackID.isEmpty {
            parts.append(stylePackID)
        }
        if let references, !references.isEmpty {
            parts.append(references)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
