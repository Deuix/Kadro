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
                        
                        // Dynamic text fields
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
                            
                            // Carousel specific
                            if !sortedSlides.isEmpty {
                                editorialSlidesSection(sortedSlides)
                            }
                            
                            // Video specific
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
                        
                        Spacer(minLength: 80) // Bottom bar padding
                    }
                    .padding(.bottom, 60)
                }
                .background(Color.kadroIvory)
                
                // Floating Bottom Action Bar
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
                    Task {
                        await handlePromptGeneration(request)
                    }
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
            // Top Nav
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.kadroCharcoal)
                        .frame(width: 44, height: 44)
                        .background(Color.kadroSoftWhite)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.kadroSand, lineWidth: 0.5))
                }
                Spacer()
                
                // Badges
                HStack(spacing: 8) {
                    KadroStatusBadge(title: project.type.rawValue.uppercased(), color: .kadroWarmGray)
                    KadroStatusBadge(title: project.status.rawValue, color: statusColor(for: project.status))
                }
            }
            
            // Title
            Text(project.title.isEmpty ? "Без названия" : project.title)
                .font(.custom("New York", size: 36).weight(.bold))
                .foregroundColor(.kadroCharcoal)
                .lineSpacing(4)
            
            Text(project.updatedAt.formatted(date: .long, time: .shortened))
                .font(.custom("New York", size: 14))
                .foregroundColor(.kadroWarmGray)
                .italic()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Visual Section (Hero Image)
    
    @ViewBuilder
    private var visualHeaderSection: some View {
        if let asset = coverPreviewAsset {
            // Show large image
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
                    .foregroundColor(.kadroCharcoal)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.kadroSoftWhite)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.kadroSand, lineWidth: 0.5))
                }
                .disabled(isGeneratingVisual)
            }
        } else if selectedStylePackReferenceCount > 0 {
            // Show generator CTA
            Button {
                visualPromptText = project.generatedCoverImagePrompt ?? ""
                visualPromptRequest = DetailVisualPromptRequest(target: .cover, title: coverButtonTitle)
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.kadroWarmGray)
                    Text("Сгенерировать обложку (AI)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.kadroCharcoal)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color.kadroSoftWhite)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.kadroSand, style: StrokeStyle(lineWidth: 1, dash: [6])))
                .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)
            .disabled(isGeneratingVisual)
        }
    }
    
    // MARK: - Editorial Text Block
    
    private func editorialTextSection(title: String, bodyText: String, field: EditableTextField) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(alignment: .bottom) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.kadroWarmGray)
                
                Spacer()
                
                // Inline Tools
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
                            .foregroundColor(copiedFieldID == field ? .kadroSuccess : .kadroWarmGray)
                    }
                    
                    Button {
                        textEditRequest = TextEditRequest(title: title, field: field, text: bodyText)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.kadroWarmGray)
                    }
                }
            }
            
            // Text Content (No card backgrounds, editorial look)
            Text(bodyText)
                .font(.custom("New York", size: 18).weight(.regular))
                .lineSpacing(6)
                .foregroundColor(.kadroCharcoal)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 24)
    }
    
    private func hashtagsSection(_ hashtags: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ХЭШТЕГИ")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.kadroWarmGray)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(hashtags.split(separator: " ").map(String.init), id: \.self) { hashtag in
                        Text(hashtag)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.kadroCharcoal)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.kadroSoftWhite)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.kadroSand, lineWidth: 0.5))
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Copy tags inline
            Button {
                UIPasteboard.general.string = hashtags
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                    Text("Скопировать всё")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.kadroWarmGray)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Bento Carousel Slides
    
    private func editorialSlidesSection(_ slides: [CarouselSlide]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                Text("СЛАЙДЫ КАРУСЕЛИ")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.kadroWarmGray)
                
                Spacer()
                
                if !generatedSlidePreviewAssets.isEmpty {
                    KadroDownloadGeneratedImagesButton(assets: generatedSlidePreviewAssets, isDisabled: isGeneratingVisual) { isDownloading in
                        Image(systemName: isDownloading ? "arrow.down.circle.fill" : "square.and.arrow.down")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.kadroCharcoal)
                    }
                }
                
                Button {
                    Task { await generateAllSlideVisuals() }
                } label: {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.kadroCharcoal)
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
                .padding(.bottom, 16) // For slight shadow
            }
        }
    }
    
    private func bentoSlideCard(_ slide: CarouselSlide) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Visual Area
            if let asset = slidePreviewAsset(for: slide) {
                KadroPreviewableGeneratedImage(asset: asset, cornerRadius: 20)
                    .padding(8)
            } else {
                ZStack {
                    Color.kadroIvory
                    
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
                        .foregroundColor(.kadroWarmGray)
                    }
                    .disabled(isGeneratingVisual || selectedStylePackReferenceCount == 0)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(8)
            }
            
            // Text Area
            VStack(alignment: .leading, spacing: 8) {
                Text("Слайд \(slide.order)")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.kadroWarmGray)
                
                Text(slide.headline)
                    .font(.custom("New York", size: 16).weight(.semibold))
                    .foregroundColor(.kadroCharcoal)
                    .lineLimit(2)
                
                if !slide.bodyText.isEmpty {
                    Text(slide.bodyText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.kadroCharcoal.opacity(0.8))
                        .lineLimit(3)
                }
                
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .frame(width: 240, height: 380)
        .background(Color.kadroSoftWhite)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.kadroSand, lineWidth: 0.5))
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
                .overlay(Capsule().stroke(Color.kadroSand, lineWidth: 0.5))
                // Beautiful inner shadow effect native to the style
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
                .fill(Color.kadroIvory.opacity(0.8))
                .ignoresSafeArea()
                .backdropFilter()
        )
    }

    // MARK: - Overlays
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .backdropFilter()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.kadroCharcoal)
                Text(isGeneratingVisual ? visualLoadingTitle : "Переписываем историю")
                    .font(.custom("New York", size: 24).weight(.medium))
                    .foregroundColor(.kadroCharcoal)
                Text(isGeneratingVisual ? visualLoadingSubtitle : "ИИ создает новую комбинацию...")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.kadroWarmGray)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(Color.kadroIvory)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        }
    }
    
    // MARK: - Logic & Properties
    
    private var coverPreviewAsset: KadroPreviewImageAsset? {
        guard let data = project.generatedCoverImageData else { return nil }
        return KadroPreviewImageAsset(
            id: "project-cover-\(project.id.uuidString)",
            title: project.title.isEmpty ? "Cover" : project.title,
            subtitle: nil, // Removed ugly meta
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
        if isInstagramPost {
            return project.generatedCoverImageData == nil ? "Создать обложку поста" : "Изменить обложку"
        }
        return project.generatedCoverImageData == nil ? "Создать обложку" : "Изменить обложку"
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

// MARK: - TextEditSheet Mock (Assumed to exist in codebase)
// If it doesn't, ensure you have the actual `TextEditSheet` struct or add it.

#Preview {
    NavigationStack {
        ContentProjectDetailView(project: ContentProject(title: "Эстетика минимализма", rawInput: "Сырая идея про дизайн", type: .post, status: .ready, platform: .instagram))
    }
    .environment(AppState())
#if canImport(SwiftData)
    .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
#endif
}
