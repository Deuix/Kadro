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
        case .cover: return L10n.Generated.useAsCover
        case .slide: return L10n.Generated.useForSlide
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
    @State private var visualLoadingTitle: String = ""
    @State private var visualLoadingSubtitle: String = ""
    
    private let styleImageService = KadroStyleImageService()
    
    private var project: ContentProject { result.project }
    private var isInstagramPost: Bool { project.platform == .instagram && project.type == .post }
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
                    if isInstagramPost {
                        instagramPostResultContent
                    } else {
                        heroCard
                        visualPreviewSection
                        
                        if !result.payload.hook.isEmpty { textSection(title: L10n.Generated.hook, body: result.payload.hook) }
                        if !result.payload.mainText.isEmpty { textSection(title: L10n.Generated.mainText, body: result.payload.mainText) }
                        if !result.payload.cta.isEmpty { textSection(title: L10n.Generated.cta, body: result.payload.cta) }
                        if !result.payload.shortVersion.isEmpty { textSection(title: L10n.Generated.shortVersion, body: result.payload.shortVersion) }
                        if !result.payload.caption.isEmpty { textSection(title: L10n.Generated.caption, body: result.payload.caption) }
                        if !result.payload.hashtags.isEmpty { tagSection }
                        if !result.payload.carousel.slides.isEmpty { carouselSection }
                        if !result.payload.reels.scriptBeats.isEmpty || !result.payload.reels.onScreenText.isEmpty || !result.payload.reels.coverIdea.isEmpty { reelsSection }
                        if !result.payload.stories.isEmpty { storiesSection }
                        if !result.payload.variants.isEmpty { variantsSection }
                        if !result.payload.suggestedNextActions.isEmpty { nextActionsSection }
                        metadataSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.kadroIvory)
            .navigationTitle(L10n.Generated.navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.close) { dismiss() }
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
                L10n.Generated.visualError,
                isPresented: Binding(get: { visualErrorMessage != nil }, set: { if !$0 { visualErrorMessage = nil } }),
                actions: { Button(L10n.Common.ok, role: .cancel) { visualErrorMessage = nil } },
                message: { Text(visualErrorMessage ?? L10n.Common.errorMessage) }
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
    
    private var instagramPostResultContent: some View {
        VStack(spacing: 20) {
            visualPreviewSection
            if !result.payload.mainText.isEmpty {
                textSection(title: L10n.Generated.postMainText, body: result.payload.mainText)
            }
            if !result.payload.shortVersion.isEmpty {
                textSection(title: L10n.Generated.shortVersion, body: result.payload.shortVersion)
            }
        }
    }
    
    private var heroCard: some View {
        KadroCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    KadroStatusBadge(title: result.project.type.displayName, color: .kadroLime)
                    Spacer()
                    Text(L10n.Generated.savedToContent).font(.kadroCaption).foregroundColor(.kadroWarmGray)
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
                Text(isInstagramPost ? L10n.Generated.visualSectionPost : L10n.Generated.visualSectionGeneric).font(.kadroTitle3).foregroundColor(.kadroCharcoal)

                if let selectedStylePack {
                    Text(L10n.Generated.stylePackLabel(selectedStylePack.displayName)).font(.kadroBodyMedium).foregroundColor(.kadroCharcoal)
                    if !isInstagramPost {
                        Text(L10n.Generated.referencesFound(selectedStylePackReferenceCount)).font(.kadroFootnote).foregroundColor(.kadroWarmGray)
                    }
                    
                    if let coverPreviewAsset {
                        KadroPreviewableGeneratedImage(asset: coverPreviewAsset)
                    }
                    
                    HStack(spacing: 10) {
                        actionButton(title: coverButtonTitle) {
                            visualPromptText = project.generatedCoverImagePrompt ?? ""
                            visualPromptRequest = VisualPromptRequest(target: .cover, title: coverButtonTitle)
                        }
                        
                        if !slides.isEmpty {
                            actionButton(title: L10n.Generated.allVisuals) {
                                Task { await generateAllSlideVisuals() }
                            }
                        }
                    }
                } else {
                    Text(L10n.Generated.noStylePack).font(.kadroCallout).foregroundColor(.kadroWarmGray)
                }
            }
        }
    }
    
    private var coverButtonTitle: String {
        if isInstagramPost {
            return project.generatedCoverImageData == nil ? L10n.Generated.createCoverImage : L10n.Generated.regenerateCoverImage
        }
        return project.generatedCoverImageData == nil ? L10n.Generated.createCover : L10n.Generated.regenerateCover
    }
    
    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: L10n.Generated.hashtags)
            KadroFlowLayout(spacing: 8) {
                ForEach(result.payload.hashtags, id: \.self) { hashtag in
                    KadroChip(title: hashtag, isSelected: false) {}.allowsHitTesting(false)
                }
            }
        }
    }
    
    private var carouselSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Generated.carouselSlides)
                    .font(.kadroTitle3)
                    .foregroundColor(.kadroCharcoal)
                Spacer()
                if !generatedSlidePreviewAssets.isEmpty {
                    KadroDownloadGeneratedImagesButton(assets: generatedSlidePreviewAssets, isDisabled: isGeneratingVisual) { isDownloading in
                        Text(isDownloading ? L10n.Generated.downloading : L10n.Generated.downloadAll)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroLime)
                    }
                }
            }
            VStack(spacing: 10) {
                ForEach(slides) { slide in
                    KadroCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.Generated.slideFormat(slide.order)).font(.kadroCaption).foregroundColor(.kadroWarmGray)
                            Text(slide.headline).font(.kadroTitle3).foregroundColor(.kadroCharcoal)
                            Text(slide.bodyText).font(.kadroBody).foregroundColor(.kadroWarmGray)
                            if let cta = slide.ctaText, !cta.isEmpty { Text(cta).font(.kadroCallout).foregroundColor(.kadroCharcoal) }
                            if let asset = slidePreviewAsset(for: slide) {
                                KadroPreviewableGeneratedImage(asset: asset)
                            }
                            actionButton(title: slide.generatedImageData == nil ? L10n.Generated.createSlideVisual : L10n.Generated.regenerateSlideVisual) {
                                visualPromptText = slide.generatedImagePrompt ?? ""
                                visualPromptRequest = VisualPromptRequest(target: .slide(slide.id), title: slide.generatedImageData == nil ? L10n.Generated.createSlideVisual : L10n.Generated.regenerateSlideVisual)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var reelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: L10n.Generated.reelsSection)
            if !result.payload.reels.hook.isEmpty { textSection(title: L10n.Generated.reelsHook, body: result.payload.reels.hook) }
            if !result.payload.reels.scriptBeats.isEmpty { bulletSection(title: L10n.Generated.scriptBeats, items: result.payload.reels.scriptBeats) }
            if !result.payload.reels.onScreenText.isEmpty { bulletSection(title: L10n.Generated.onScreenText, items: result.payload.reels.onScreenText) }
            if !result.payload.reels.coverIdea.isEmpty { textSection(title: L10n.Generated.coverIdea, body: result.payload.reels.coverIdea) }
        }
    }
    
    private var storiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: L10n.Generated.storiesSection)
            VStack(spacing: 10) {
                ForEach(Array(result.payload.stories.enumerated()), id: \.offset) { index, frame in
                    KadroCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.Generated.storyFormat(index + 1)).font(.kadroCaption).foregroundColor(.kadroWarmGray)
                            Text(frame.title).font(.kadroTitle3).foregroundColor(.kadroCharcoal)
                            Text(frame.body).font(.kadroBody).foregroundColor(.kadroWarmGray)
                            if !frame.stickerIdea.isEmpty { Text(L10n.Generated.stickerFormat(frame.stickerIdea)).font(.kadroCallout).foregroundColor(.kadroCharcoal) }
                        }
                    }
                }
            }
        }
    }
    
    private var variantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: L10n.Generated.variants)
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
        bulletSection(title: L10n.Generated.nextActions, items: result.payload.suggestedNextActions)
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
        visualLoadingTitle = L10n.Generated.loadingCoverTitle
        visualLoadingSubtitle = L10n.Generated.loadingCoverSubtitle
        
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
        visualLoadingTitle = L10n.Generated.loadingSlideTitle
        visualLoadingSubtitle = L10n.Generated.loadingSlideSubtitle(slide.order)
        
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
            visualLoadingTitle = L10n.Generated.loadingAllSlidesTitle
            visualLoadingSubtitle = L10n.Generated.loadingAllSlidesSubtitle(index + 1, slides.count, slide.headline)

            do {
                let response = try await styleImageService.generateSlideVisual(project: project, slide: slide, brandProfile: brandProfile)
                try persistGeneratedVisual(response, target: .slide(slide.id))
            } catch {
                visualErrorMessage = L10n.Generated.slideError(slide.order, error.localizedDescription)
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
            throw NSError(domain: "KadroStyleImageService", code: 1, userInfo: [NSLocalizedDescriptionKey: L10n.Generated.saveVisualError])
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
                throw NSError(domain: "KadroStyleImageService", code: 2, userInfo: [NSLocalizedDescriptionKey: L10n.Generated.findSlideError])
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
            title: L10n.Generated.slideFormat(slide.order),
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

