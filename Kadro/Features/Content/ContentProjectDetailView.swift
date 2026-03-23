import SwiftUI
import SwiftData

private struct PendingGeneratedVisualPreview: Identifiable {
    let target: KadroStyleVisualTarget
    let result: KadroGeneratedStyleImageResponse
    
    var id: String {
        result.id + "-" + target.previewKey
    }
}

private struct DetailVisualPromptRequest: Identifiable {
    let target: KadroStyleVisualTarget
    let title: String
    
    var id: String {
        switch target {
        case .cover:
            return "cover"
        case .slide(let id):
            return "slide-\(id.uuidString)"
        }
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
        case .cover: return L10n.Generated.useAsCover
        case .slide: return L10n.Generated.useForSlide
        }
    }
}

// MARK: - Editable Text Field

private enum EditableTextField: String, Identifiable {
    case rawInput, hook, mainText, cta, shortVersion, caption, scriptBeats, onScreenText, coverIdea, hashtags
    var id: String { rawValue }
}

private struct TextEditRequest: Identifiable {
    let id = UUID()
    let title: String
    let field: EditableTextField
    var text: String
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
    @State private var visualPromptRequest: DetailVisualPromptRequest?
    @State private var visualPromptText: String = ""
    @State private var visualLoadingTitle: String = ""
    @State private var visualLoadingSubtitle: String = ""
    @State private var textEditRequest: TextEditRequest?
    @State private var copiedFieldID: EditableTextField?
    @Environment(\.colorScheme) private var colorScheme
    
    private let aiService = KadroAIService()
    private let styleImageService = KadroStyleImageService()
    
    private var isInstagramPost: Bool {
        project.platform == .instagram && project.type == .post
    }
    
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
    
    private var generatedSlidePreviewAssets: [KadroPreviewImageAsset] {
        sortedSlides.compactMap(slidePreviewAsset(for:))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isInstagramPost {
                    visualGenerationCard
                    if let mainText = project.mainText, !mainText.isEmpty {
                        textSection(title: L10n.Generated.postMainText, body: mainText, field: .mainText)
                    }
                    if let shortVersion = project.shortVersion, !shortVersion.isEmpty {
                        textSection(title: L10n.Generated.shortVersion, body: shortVersion, field: .shortVersion)
                    }
                } else {
                    heroCard
                    visualGenerationCard

                    if !project.rawInput.isEmpty {
                        textSection(title: L10n.Generated.sourceIdea, body: project.rawInput, field: .rawInput)
                    }

                    if let hook = project.hook, !hook.isEmpty {
                        textSection(title: L10n.Generated.hook, body: hook, field: .hook)
                    }

                    if let mainText = project.mainText, !mainText.isEmpty {
                        textSection(title: project.type == .stories ? L10n.Generated.storiesDraft : L10n.Generated.mainText, body: mainText, field: .mainText)
                    }

                    if let cta = project.cta, !cta.isEmpty {
                        textSection(title: L10n.Generated.cta, body: cta, field: .cta)
                    }

                    if let shortVersion = project.shortVersion, !shortVersion.isEmpty {
                        textSection(title: L10n.Generated.shortVersion, body: shortVersion, field: .shortVersion)
                    }

                    if let caption = project.caption, !caption.isEmpty {
                        textSection(title: L10n.Generated.caption, body: caption, field: .caption)
                    }

                    if let hashtags = project.hashtags, !hashtags.isEmpty {
                        hashtagsSection(hashtags)
                    }

                    if !sortedSlides.isEmpty {
                        slidesSection(sortedSlides)
                    }

                    if let scriptBeats = project.scriptBeats, !scriptBeats.isEmpty {
                        textSection(title: L10n.Generated.scriptBeats, body: scriptBeats, field: .scriptBeats)
                    }

                    if let onScreenText = project.onScreenText, !onScreenText.isEmpty {
                        textSection(title: L10n.Generated.onScreenText, body: onScreenText, field: .onScreenText)
                    }

                    if let coverIdea = project.coverIdea, !coverIdea.isEmpty {
                        textSection(title: L10n.Generated.coverIdea, body: coverIdea, field: .coverIdea)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.kadroBackground(for: colorScheme))
        .navigationTitle(project.title.isEmpty ? L10n.Common.untitled : project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.Generated.newVersion) {
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
        .sheet(item: $visualPromptRequest) { request in
            VisualPromptInputSheet(title: request.title, promptText: $visualPromptText) {
                Task {
                    await handlePromptGeneration(request)
                }
            }
        }
        .alert(
            L10n.Common.errorTitle,
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            ),
            actions: {
                Button(L10n.Common.ok, role: .cancel) {
                    errorMessage = nil
                }
            },
            message: {
                Text(errorMessage ?? L10n.Common.errorMessage)
            }
        )
        .sheet(item: $textEditRequest) { request in
            TextEditSheet(
                title: request.title,
                text: request.text
            ) { updatedText in
                saveEditedText(updatedText, for: request.field)
            }
        }
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
                    KadroStatusBadge(title: project.type.displayName, color: .kadroLime)
                    KadroStatusBadge(title: project.status.displayName, color: statusColor(for: project.status))
                    Spacer()
                }
                
                Text(project.title.isEmpty ? L10n.Common.untitled : project.title)
                    .font(.kadroTitle2)
                    .foregroundColor(.kadroCharcoal)
                
                HStack(spacing: 8) {
                    Text(project.platform.rawValue)
                        .font(.kadroFootnote)
                        .foregroundColor(.kadroWarmGray)
                    
                    if let tone = project.tone {
                        Text("· \(tone.displayName)")
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                    }

                    if let goal = project.goal {
                        Text("· \(goal.displayName)")
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
                Text(isInstagramPost ? L10n.Generated.visualSectionPost : L10n.Generated.visualDraft)
                    .font(.kadroTitle3)
                    .foregroundColor(.kadroCharcoal)
                
                if let selectedStylePack {
                    Text(L10n.Generated.stylePackLabel(selectedStylePack.displayName))
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroCharcoal)
                    Text(selectedStylePack.shortDescription)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                    Text(L10n.Generated.referencesFound(selectedStylePackReferenceCount))
                        .font(.kadroFootnote)
                        .foregroundColor(.kadroWarmGray)
                    Text(selectedStylePack.referenceFolder)
                        .font(.kadroCaption)
                        .foregroundColor(.kadroWarmGray)
                    
                    if let asset = coverPreviewAsset {
                        KadroPreviewableGeneratedImage(asset: asset)
                        if let meta = coverMetaText {
                            Text(meta)
                                .font(.kadroCaption)
                                .foregroundColor(.kadroWarmGray)
                        }
                    }
                    
                    Button {
                        visualPromptText = project.generatedCoverImagePrompt ?? ""
                        visualPromptRequest = DetailVisualPromptRequest(
                            target: .cover,
                            title: coverButtonTitle
                        )
                    } label: {
                        Text(coverButtonTitle)
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
                    Text(L10n.Generated.detailNoStylePack)
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
                    Text(isGeneratingVisual ? visualLoadingTitle : L10n.Generated.regeneratingTitle)
                        .font(.kadroTitle3)
                        .foregroundColor(.kadroCharcoal)
                    Text(isGeneratingVisual ? visualLoadingSubtitle : L10n.Generated.regeneratingSubtitle)
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
            KadroSectionHeader(title: L10n.Generated.hashtags)
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
                Button(L10n.Generated.allVisuals) {
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
                            Text(L10n.Generated.slideFormat(slide.order))
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
                            
                            if let asset = slidePreviewAsset(for: slide) {
                                KadroPreviewableGeneratedImage(asset: asset)
                                if let meta = slideMetaText(slide) {
                                    Text(meta)
                                        .font(.kadroCaption)
                                        .foregroundColor(.kadroWarmGray)
                                }
                            }
                            
                            Button {
                                visualPromptText = slide.generatedImagePrompt ?? ""
                                visualPromptRequest = DetailVisualPromptRequest(
                                    target: .slide(slide.id),
                                    title: slide.generatedImageData == nil ? L10n.Generated.createSlideVisual : L10n.Generated.regenerateSlideVisual
                                )
                            } label: {
                                Text(slide.generatedImageData == nil ? L10n.Generated.createSlideVisual : L10n.Generated.regenerateSlideVisual)
                                    .font(.kadroFootnote)
                                    .foregroundColor(.kadroCharcoal)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.kadroBackground(for: colorScheme))
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
    
    private func textSection(title: String, body: String, field: EditableTextField) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                KadroSectionHeader(title: title)
                Spacer()
                
                // Copy button
                Button {
                    UIPasteboard.general.string = body
                    withAnimation(.easeInOut(duration: 0.25)) {
                        copiedFieldID = field
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if copiedFieldID == field {
                                copiedFieldID = nil
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedFieldID == field ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .medium))
                        if copiedFieldID == field {
                            Text(L10n.Generated.copied)
                                .font(.kadroCaption)
                        }
                    }
                    .foregroundColor(copiedFieldID == field ? .kadroSuccess : .kadroWarmGray)
                }
                .buttonStyle(.plain)
                
                // Edit button
                Button {
                    textEditRequest = TextEditRequest(title: title, field: field, text: body)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.kadroWarmGray)
                }
                .buttonStyle(.plain)
            }
            KadroCard {
                Text(body)
                    .font(.kadroBody)
                    .foregroundColor(.kadroCharcoal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
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
    
    private var coverButtonTitle: String {
        if isInstagramPost {
            return project.generatedCoverImageData == nil ? L10n.Generated.createCoverImage : L10n.Generated.regenerateCoverImage
        }
        return project.generatedCoverImageData == nil ? L10n.Generated.createCover : L10n.Generated.regenerateCover
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
    
    // MARK: - Save Edited Text
    
    private func saveEditedText(_ newText: String, for field: EditableTextField) {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        switch field {
        case .rawInput:     project.rawInput = trimmed
        case .hook:         project.hook = trimmed
        case .mainText:     project.mainText = trimmed
        case .cta:          project.cta = trimmed
        case .shortVersion: project.shortVersion = trimmed
        case .caption:      project.caption = trimmed
        case .scriptBeats:  project.scriptBeats = trimmed
        case .onScreenText: project.onScreenText = trimmed
        case .coverIdea:    project.coverIdea = trimmed
        case .hashtags:     project.hashtags = trimmed
        }
        
        project.updatedAt = Date()
        try? modelContext.save()
    }
    
    @MainActor
    private func regenerateProject() async {
        guard !isRegenerating else { return }
        let trimmedInput = project.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            errorMessage = L10n.Generated.noSourceIdea
            return
        }

        isRegenerating = true
        errorMessage = nil

        let context = KadroGenerationContext(
            inputSource: "Regeneration",
            rawInput: trimmedInput,
            outputType: project.type,
            tone: project.tone,
            goal: project.goal,
            platform: project.platform,
            contentLanguage: project.contentLanguage ?? profiles.first?.language ?? "Русский",
            formatDetail: project.formatDetail,
            preferredImageAspectRatio: project.preferredImageAspectRatio,
            desiredSlideCount: project.desiredSlideCount,
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
    private func handlePromptGeneration(_ request: DetailVisualPromptRequest) async {
        switch request.target {
        case .cover:
            await generateCoverVisualDraft(promptOverride: visualPromptText)
        case .slide(let id):
            guard let slide = sortedSlides.first(where: { $0.id == id }) else { return }
            await generateSlideVisualDraft(slide, promptOverride: visualPromptText)
        }
    }
    
    @MainActor
    private func generateCoverVisualDraft(promptOverride: String? = nil) async {
        guard !isGeneratingVisual else { return }
        isGeneratingVisual = true
        errorMessage = nil
        visualLoadingTitle = L10n.Generated.loadingCoverTitle
        visualLoadingSubtitle = L10n.Generated.loadingCoverSubtitle
        
        do {
            let response = try await styleImageService.generateCoverVisual(project: project, brandProfile: brandProfile, promptOverride: promptOverride)
            generatedVisualPreview = PendingGeneratedVisualPreview(target: .cover, result: response)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGeneratingVisual = false
    }
    
    @MainActor
    private func generateSlideVisualDraft(_ slide: CarouselSlide, promptOverride: String? = nil) async {
        guard !isGeneratingVisual else { return }
        isGeneratingVisual = true
        errorMessage = nil
        visualLoadingTitle = L10n.Generated.loadingSlideTitle
        visualLoadingSubtitle = L10n.Generated.loadingSlideSubtitle(slide.order)
        
        do {
            let response = try await styleImageService.generateSlideVisual(project: project, slide: slide, brandProfile: brandProfile, promptOverride: promptOverride)
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
            visualLoadingTitle = L10n.Generated.loadingAllSlidesTitle
            visualLoadingSubtitle = L10n.Generated.loadingAllSlidesSubtitle(index + 1, slides.count, slide.headline)

            do {
                let response = try await styleImageService.generateSlideVisual(project: project, slide: slide, brandProfile: brandProfile)
                try persistGeneratedVisual(response, target: .slide(slide.id))
            } catch {
                errorMessage = L10n.Generated.slideError(slide.order, error.localizedDescription)
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
            id: "project-cover-\(project.id.uuidString)",
            title: project.title.isEmpty ? "Cover" : project.title,
            subtitle: coverMetaText,
            filenameStem: "kadro-\(project.title.isEmpty ? "cover" : project.title)-cover",
            imageData: data
        )
    }
    
    private func slidePreviewAsset(for slide: CarouselSlide) -> KadroPreviewImageAsset? {
        guard let data = slide.generatedImageData else { return nil }
        return KadroPreviewImageAsset(
            id: "project-slide-\(slide.id.uuidString)",
            title: L10n.Generated.slideFormat(slide.order),
            subtitle: slideMetaText(slide),
            filenameStem: "kadro-\(project.title.isEmpty ? "carousel" : project.title)-slide-\(slide.order)",
            imageData: data
        )
    }
}

#Preview {
    NavigationStack {
        ContentProjectDetailView(project: ContentProject(title: "Пример", rawInput: "Сырая идея", type: .post, status: .ready, platform: .instagram))
    }
    .environment(AppState())
    .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
