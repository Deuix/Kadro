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
        case .cover: return "Использовать как обложку"
        case .slide: return "Использовать для слайда"
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
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
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        heroHeader
                        visualHeaderSection
                        
                        VStack(spacing: 32) {
                            if !project.rawInput.isEmpty {
                                editorialTextSection(title: "Моя идея", bodyText: project.rawInput, field: .rawInput)
                            }
                            if let hook = project.hook, !hook.isEmpty {
                                editorialTextSection(title: "Хук (Заголовок)", bodyText: hook, field: .hook)
                            }
                            if let mainText = project.mainText, !mainText.isEmpty {
                                editorialTextSection(title: project.type == .stories ? "Сценарий (Stories)" : "Основной текст", bodyText: mainText, field: .mainText)
                            }
                            if let cta = project.cta, !cta.isEmpty {
                                editorialTextSection(title: "Призыв к действию", bodyText: cta, field: .cta)
                            }
                            if let shortVersion = project.shortVersion, !shortVersion.isEmpty {
                                editorialTextSection(title: "Короткая версия", bodyText: shortVersion, field: .shortVersion)
                            }
                            if let caption = project.caption, !caption.isEmpty {
                                editorialTextSection(title: "Описание (Caption)", bodyText: caption, field: .caption)
                            }
                            if let hashtags = project.hashtags, !hashtags.isEmpty {
                                hashtagsSection(hashtags)
                            }
                            if !sortedSlides.isEmpty {
                                editorialSlidesSection(sortedSlides)
                            }
                            if let scriptBeats = project.scriptBeats, !scriptBeats.isEmpty {
                                editorialTextSection(title: "Сценарий (Блоки)", bodyText: scriptBeats, field: .scriptBeats)
                            }
                            if let onScreenText = project.onScreenText, !onScreenText.isEmpty {
                                editorialTextSection(title: "Текст на экране", bodyText: onScreenText, field: .onScreenText)
                            }
                            if let coverIdea = project.coverIdea, !coverIdea.isEmpty {
                                editorialTextSection(title: "Идея обложки", bodyText: coverIdea, field: .coverIdea)
                            }
                        }
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.bottom, 60)
                }
                .background(Color.kadroBackground(for: colorScheme))
                
                floatingActionBar
            }
            .navigationBarHidden(true)
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
                    Task { await handlePromptGeneration(request) }
                }
            }
            .alert(
                "Ошибка",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                ),
                actions: { Button("ОК", role: .cancel) { errorMessage = nil } },
                message: { Text(errorMessage ?? "Произошла ошибка") }
            )
            .sheet(item: $textEditRequest) { request in
                TextEditSheet(title: request.title, text: request.text) { updatedText in
                    saveEditedText(updatedText, for: request.field)
                }
            }
            .overlay {
                if isRegenerating || isGeneratingVisual {
                    loadingOverlay
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.kadroPrimary(for: colorScheme))
                        .frame(width: 44, height: 44)
                        .background(Color.kadroCard(for: colorScheme))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                }
                Spacer()
                HStack(spacing: 8) {
                    KadroStatusBadge(title: project.type.rawValue.uppercased(), color: .kadroWarmGray)
                    KadroStatusBadge(title: project.status.rawValue, color: statusColor(for: project.status))
                }
            }
            
            Text(project.title.isEmpty ? "Без названия" : project.title)
                .font(.custom("New York", size: 36).weight(.bold))
                .foregroundColor(.kadroPrimary(for: colorScheme))
                .lineSpacing(4)
            
            Text(project.updatedAt.formatted(date: .long, time: .shortened))
                .font(.custom("New York", size: 14))
                .foregroundColor(.kadroSecondary(for: colorScheme))
                .italic()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Visual Section
    
    @ViewBuilder
    private var visualHeaderSection: some View {
        if let asset = coverPreviewAsset {
            VStack(spacing: 12) {
                KadroPreviewableGeneratedImage(asset: asset, cornerRadius: 24)
                    .padding(.horizontal, 24)
                
                Button {
                    visualPromptText = project.generatedCoverImagePrompt ?? ""
                    visualPromptRequest = DetailVisualPromptRequest(target: .cover, title: coverButtonTitle)
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(coverButtonTitle)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.kadroPrimary(for: colorScheme))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.kadroCard(for: colorScheme))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                }
                .disabled(isGeneratingVisual)
            }
        } else if selectedStylePackReferenceCount > 0 {
            Button {
                visualPromptText = project.generatedCoverImagePrompt ?? ""
                visualPromptRequest = DetailVisualPromptRequest(target: .cover, title: coverButtonTitle)
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.kadroSecondary(for: colorScheme))
                    Text("Сгенерировать обложку (AI)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.kadroPrimary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color.kadroCard(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.kadroBorderColor(for: colorScheme), style: StrokeStyle(lineWidth: 1, dash: [6])))
                .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)
            .disabled(isGeneratingVisual)
        }
    }
    
    // MARK: - Editorial Text Block
    
    private func editorialTextSection(title: String, bodyText: String, field: EditableTextField) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.kadroSecondary(for: colorScheme))
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        UIPasteboard.general.string = bodyText
                        withAnimation(.easeInOut(duration: 0.25)) { copiedFieldID = field }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if copiedFieldID == field { copiedFieldID = nil }
                        }
                    } label: {
                        Image(systemName: copiedFieldID == field ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(copiedFieldID == field ? .kadroSuccess : .kadroSecondary(for: colorScheme))
                    }
                    
                    Button {
                        textEditRequest = TextEditRequest(title: title, field: field, text: bodyText)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.kadroSecondary(for: colorScheme))
                    }
                }
            }
            
            Text(bodyText)
                .font(.custom("New York", size: 18).weight(.regular))
                .lineSpacing(6)
                .foregroundColor(.kadroPrimary(for: colorScheme))
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 24)
    }
    
    private func hashtagsSection(_ hashtags: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ХЭШТЕГИ")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.kadroSecondary(for: colorScheme))
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(hashtags.split(separator: " ").map(String.init), id: \.self) { hashtag in
                        Text(hashtag)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.kadroPrimary(for: colorScheme))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.kadroCard(for: colorScheme))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Button {
                UIPasteboard.general.string = hashtags
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                    Text("Скопировать всё")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.kadroSecondary(for: colorScheme))
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Carousel Slides
    
    private func editorialSlidesSection(_ slides: [CarouselSlide]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                Text("СЛАЙДЫ КАРУСЕЛИ")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.kadroSecondary(for: colorScheme))
                
                Spacer()
                
                if !generatedSlidePreviewAssets.isEmpty {
                    KadroDownloadGeneratedImagesButton(assets: generatedSlidePreviewAssets, isDisabled: isGeneratingVisual) { isDownloading in
                        Image(systemName: isDownloading ? "arrow.down.circle.fill" : "square.and.arrow.down")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.kadroPrimary(for: colorScheme))
                    }
                }
                
                Button {
                    Task { await generateAllSlideVisuals() }
                } label: {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.kadroPrimary(for: colorScheme))
                }
                .disabled(isGeneratingVisual || selectedStylePackReferenceCount == 0)
                .opacity((isGeneratingVisual || selectedStylePackReferenceCount == 0) ? 0.5 : 1)
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(slides) { slide in
                        bentoSlideCard(slide)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func bentoSlideCard(_ slide: CarouselSlide) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let asset = slidePreviewAsset(for: slide) {
                KadroPreviewableGeneratedImage(asset: asset, cornerRadius: 20)
                    .padding(8)
            } else {
                ZStack {
                    Color.kadroBackground(for: colorScheme)
                    
                    Button {
                        visualPromptText = slide.generatedImagePrompt ?? ""
                        visualPromptRequest = DetailVisualPromptRequest(
                            target: .slide(slide.id),
                            title: "Создать вижуал"
                        )
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 24, weight: .light))
                            Text("AI Visual")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.kadroSecondary(for: colorScheme))
                    }
                    .disabled(isGeneratingVisual || selectedStylePackReferenceCount == 0)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Слайд \(slide.order)")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.kadroSecondary(for: colorScheme))
                
                Text(slide.headline)
                    .font(.custom("New York", size: 16).weight(.semibold))
                    .foregroundColor(.kadroPrimary(for: colorScheme))
                    .lineLimit(2)
                
                if !slide.bodyText.isEmpty {
                    Text(slide.bodyText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.kadroSecondary(for: colorScheme))
                        .lineLimit(3)
                }
                
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .frame(width: 240, height: 380)
        .background(Color.kadroCard(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
    }
    
    // MARK: - Floating Bottom Bar
    
    private var floatingActionBar: some View {
        VStack {
            Button {
                Task { await regenerateProject() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18, weight: .medium))
                    Text("Сгенерировать новый вариант")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.kadroCharcoal)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.kadroLime)
                .clipShape(Capsule())
                .shadow(color: Color.kadroLime.opacity(0.4), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(isRegenerating || isGeneratingVisual)
            .opacity((isRegenerating || isGeneratingVisual) ? 0.5 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color.kadroBackground(for: colorScheme).opacity(0.92))
                .ignoresSafeArea()
                .backdropFilter()
        )
    }

    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .backdropFilter()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.kadroPrimary(for: colorScheme))
                Text(isGeneratingVisual ? visualLoadingTitle : "Переписываем историю")
                    .font(.custom("New York", size: 24).weight(.medium))
                    .foregroundColor(.kadroPrimary(for: colorScheme))
                Text(isGeneratingVisual ? visualLoadingSubtitle : "ИИ создает новую комбинацию...")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.kadroSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(Color.kadroCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
    }
    
    // MARK: - Helpers
    
    private var coverPreviewAsset: KadroPreviewImageAsset? {
        guard let data = project.generatedCoverImageData else { return nil }
        return KadroPreviewImageAsset(
            id: "project-cover-\(project.id.uuidString)",
            title: project.title.isEmpty ? "Cover" : project.title,
            subtitle: nil,
            filenameStem: "kadro-\(project.title.isEmpty ? "cover" : project.title)-cover",
            imageData: data
        )
    }
    
    private func slidePreviewAsset(for slide: CarouselSlide) -> KadroPreviewImageAsset? {
        guard let data = slide.generatedImageData else { return nil }
        return KadroPreviewImageAsset(
            id: "project-slide-\(slide.id.uuidString)",
            title: "Слайд \(slide.order)",
            subtitle: nil,
            filenameStem: "kadro-\(project.title.isEmpty ? "carousel" : project.title)-slide-\(slide.order)",
            imageData: data
        )
    }
    
    private var coverButtonTitle: String {
        project.generatedCoverImageData == nil ? "Создать обложку (AI)" : "Изменить обложку"
    }
    
    private func statusColor(for status: ContentStatus) -> Color {
        switch status {
        case .draft: return .kadroWarmGray
        case .ready: return .kadroSuccess
        case .scheduled: return .kadroLime
        case .published: return .kadroCharcoal
        }
    }
    
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
            errorMessage = "Нет изначальной идеи для регенерации"
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
        visualLoadingTitle = "Рисуем обложку"
        visualLoadingSubtitle = "AI подбирает нужный стиль..."
        
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
        visualLoadingTitle = "Оформляем слайд"
        visualLoadingSubtitle = "Рисуем слайд номер \(slide.order)..."
        
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
            visualLoadingTitle = "Магия карусели"
            visualLoadingSubtitle = "Рисуем слайд \(index + 1) из \(slides.count)"
            
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
            throw NSError(domain: "KadroStyleImageService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось сохранить фото"])
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
                throw NSError(domain: "KadroStyleImageService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Слайд не найден"])
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
}

#Preview {
    NavigationStack {
        ContentProjectDetailView(project: ContentProject(title: "Эстетика минимализма", rawInput: "Сырая идея про дизайн", type: .post, status: .ready, platform: .instagram))
    }
    .environment(AppState())
#if canImport(SwiftData)
    .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
#endif
}
