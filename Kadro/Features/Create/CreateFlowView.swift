//
//  CreateFlowView.swift
//  Kadro
//
//  Simplified Instagram-first create flow
//

import SwiftUI
import SwiftData

// MARK: - Create Flow Steps

enum CreateStep: Int, CaseIterable {
    case service = 0
    case format = 1
    case idea = 2
    case refine = 3
    
    var title: String {
        switch self {
        case .service: return L10n.Create.stepService
        case .format: return L10n.Create.stepFormat
        case .idea: return L10n.Create.stepIdea
        case .refine: return L10n.Create.stepRefine
        }
    }
}

// MARK: - Draft Compatibility

enum InputSource: String, CaseIterable, Identifiable {
    case topic = "Идея или тема"
    case voiceNote = "Голосовая заметка"
    case textOrLink = "Текст"
    
    var id: String { rawValue }
}

// MARK: - Platform Selection

enum CreateService: String, CaseIterable, Identifiable {
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case x = "X"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .instagram: return "camera"
        case .tiktok: return "play.square"
        case .x: return "text.bubble"
        case .other: return "square.grid.2x2"
        }
    }
    
    var subtitle: String {
        switch self {
        case .instagram: return L10n.Create.serviceInstagramSubtitle
        case .tiktok: return L10n.Create.serviceComingSoon
        case .x: return L10n.Create.serviceComingSoon
        case .other: return L10n.Create.serviceComingSoon
        }
    }
    
    var isAvailable: Bool {
        self == .instagram
    }
}

enum InstagramCreateFormat: String, CaseIterable, Identifiable {
    case post = "Post"
    case story = "Story"
    case carousel = "Carousel"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .post: return "square.text.square"
        case .story: return "rectangle.portrait"
        case .carousel: return "rectangle.split.3x1"
        }
    }
    
    var subtitle: String {
        switch self {
        case .post: return L10n.Create.formatPostSubtitle
        case .story: return L10n.Create.formatStorySubtitle
        case .carousel: return L10n.Create.formatCarouselSubtitle
        }
    }
    
    var outputType: ContentType {
        switch self {
        case .post: return .post
        case .story: return .stories
        case .carousel: return .carousel
        }
    }
}

enum InstagramPostCanvas: String, CaseIterable, Identifiable {
    case square = "Квадрат"
    case portrait = "Вертикальный"
    
    var id: String { rawValue }
    
    var aspectRatio: String {
        switch self {
        case .square: return "1:1"
        case .portrait: return "4:5"
        }
    }
    
    var displayName: String {
        switch self {
        case .square: return L10n.Create.canvasSquare
        case .portrait: return L10n.Create.canvasPortrait
        }
    }

    var subtitle: String {
        switch self {
        case .square: return L10n.Create.canvasSquareSubtitle
        case .portrait: return L10n.Create.canvasPortraitSubtitle
        }
    }
    
    var formatDetail: String {
        switch self {
        case .square: return "instagram_post_square"
        case .portrait: return "instagram_post_portrait"
        }
    }
}

struct CreateFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BrandProfile]
    
    @StateObject private var voiceRecorder = VoiceNoteRecorder()
    
    @State private var currentStep: CreateStep = .service
    @State private var selectedService: CreateService?
    @State private var selectedContentLanguage: String = "Русский"
    @State private var selectedInstagramFormat: InstagramCreateFormat?
    @State private var selectedPostCanvas: InstagramPostCanvas = .portrait
    @State private var selectedCarouselSlideCount: Int = 7
    @State private var inputText: String = ""
    @State private var selectedTone: ContentTone?
    @State private var selectedGoal: ContentGoal?
    @State private var selectedStylePackID: String = StylePackLibrary.packs.first?.id ?? ""
    @State private var isGenerating = false
    @State private var isTranscribingVoiceNote = false
    @State private var appErrorMessage: String?
    @State private var latestResult: GeneratedContentResult?
    @State private var lastTranscribedRecordingIdentifier: String?
    @State private var lastTranscription: KadroVoiceTranscriptionResponse?
    
    private let aiService = KadroAIService()
    private let stylePacks = StylePackLibrary.packs
    private let transcriptionService = KadroVoiceTranscriptionService()
    private let carouselSlideOptions = Array(4...10)
    private let supportedContentLanguages = ["Русский", "English", "Türkçe", "Azərbaycan dili"]
    
    private var defaultContentLanguage: String {
        let candidate = profiles.first?.language.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return candidate.isEmpty ? "Русский" : candidate
    }
    
    private var resolvedOutputType: ContentType? {
        selectedInstagramFormat?.outputType
    }
    
    private var resolvedFormatDetail: String? {
        switch selectedInstagramFormat {
        case .post:
            return selectedPostCanvas.formatDetail
        case .story:
            return "instagram_story"
        case .carousel:
            return "instagram_carousel"
        case .none:
            return nil
        }
    }
    
    private var resolvedPreferredImageAspectRatio: String? {
        switch selectedInstagramFormat {
        case .post:
            return selectedPostCanvas.aspectRatio
        case .story:
            return "9:16"
        case .carousel:
            return "4:5"
        case .none:
            return nil
        }
    }
    
    private var resolvedDesiredSlideCount: Int? {
        selectedInstagramFormat == .carousel ? selectedCarouselSlideCount : nil
    }
    
    private var primaryButtonTitle: String {
        switch currentStep {
        case .service: return L10n.Create.continueAction
        case .format: return L10n.Create.next
        case .idea: return L10n.Create.continueAction
        case .refine:
            switch selectedInstagramFormat {
            case .post: return L10n.Create.createPost
            case .story: return L10n.Create.createStory
            case .carousel: return L10n.Create.createCarousel
            case .none: return L10n.Create.createGeneric
            }
        }
    }
    
    private var canContinue: Bool {
        switch currentStep {
        case .service:
            return selectedService?.isAvailable == true
        case .format:
            return selectedInstagramFormat != nil
        case .idea:
            return !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTranscribingVoiceNote
        case .refine:
            return !isGenerating && !selectedStylePackID.isEmpty && resolvedOutputType != nil
        }
    }
    
    private var isBusy: Bool {
        isGenerating || isTranscribingVoiceNote
    }
    
    private var loadingTitle: String {
        isTranscribingVoiceNote ? L10n.Create.loadingVoiceTitle : L10n.Create.loadingContentTitle
    }

    private var loadingSubtitle: String {
        isTranscribingVoiceNote ? L10n.Create.loadingVoiceSubtitle : L10n.Create.loadingContentSubtitle
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case .service:
                            serviceStep
                        case .format:
                            formatStep
                        case .idea:
                            ideaStep
                        case .refine:
                            refineStep
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
                .background(Color.kadroIvory)
            }
            .background(Color.kadroIvory)
            .navigationTitle(L10n.Create.navTitle)
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .sheet(item: $latestResult) { result in
                GeneratedContentView(result: result)
            }
            .alert(
                L10n.Common.errorTitle,
                isPresented: Binding(
                    get: { appErrorMessage != nil },
                    set: { if !$0 { appErrorMessage = nil } }
                ),
                actions: {
                    Button(L10n.Common.ok, role: .cancel) {
                        appErrorMessage = nil
                    }
                },
                message: {
                    Text(appErrorMessage ?? L10n.Common.errorMessage)
                }
            )
            .overlay {
                if isBusy {
                    loadingOverlay
                }
            }
            .onChange(of: voiceRecorder.completedRecordingURL) { _, newValue in
                guard let newValue else { return }
                let identifier = newValue.lastPathComponent
                guard lastTranscribedRecordingIdentifier != identifier else { return }
                Task {
                    await transcribeVoiceNote(from: newValue)
                }
            }
            .onChange(of: voiceRecorder.lastErrorMessage) { _, newValue in
                guard let newValue else { return }
                appErrorMessage = newValue
            }
            .onAppear {
                applyDraftIfNeeded()
            }
        }
    }
    
    // MARK: - Progress
    
    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(CreateStep.allCases, id: \.rawValue) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.rawValue <= currentStep.rawValue ? Color.kadroLime : Color.kadroSand)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - Step 1
    
    private var serviceStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                eyebrow: L10n.Create.stepEyebrow(1),
                title: L10n.Create.step1Title,
                subtitle: L10n.Create.step1Subtitle
            )
            
            VStack(spacing: 12) {
                ForEach(CreateService.allCases) { service in
                    Button {
                        handleServiceSelection(service)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: service.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(selectedService == service ? .kadroCharcoal : .kadroLime)
                                .frame(width: 48, height: 48)
                                .background(selectedService == service ? Color.kadroLime : Color.kadroCharcoal)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(service.rawValue)
                                    .font(.kadroBodyMedium)
                                    .foregroundColor(.kadroCharcoal)
                                Text(service.subtitle)
                                    .font(.kadroFootnote)
                                    .foregroundColor(.kadroWarmGray)
                            }
                            
                            Spacer()
                            
                            if service.isAvailable {
                                if selectedService == service {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.kadroLime)
                                }
                            } else {
                                KadroStatusBadge(title: L10n.Create.serviceComingSoon, color: .kadroWarmGray)
                            }
                        }
                        .padding(16)
                        .background(Color.kadroSoftWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(selectedService == service ? Color.kadroLime : Color.kadroSand.opacity(0.65), lineWidth: selectedService == service ? 2 : 1)
                        )
                        .opacity(service.isAvailable ? 1 : 0.72)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Create.contentLanguage)
                    .font(.kadroTitle3)
                    .foregroundColor(.kadroCharcoal)

                Text(L10n.Create.contentLanguageHint)
                    .font(.kadroCallout)
                    .foregroundColor(.kadroWarmGray)
                
                FlowLayout(spacing: 10) {
                    ForEach(supportedContentLanguages, id: \.self) { language in
                        KadroChip(title: language, isSelected: selectedContentLanguage == language) {
                            selectedContentLanguage = language
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2
    
    private var formatStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                eyebrow: L10n.Create.stepEyebrow(2),
                title: L10n.Create.step2Title,
                subtitle: L10n.Create.step2Subtitle
            )
            
            VStack(spacing: 12) {
                ForEach(InstagramCreateFormat.allCases) { format in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            selectedInstagramFormat = format
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: format.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(selectedInstagramFormat == format ? .kadroCharcoal : .kadroLime)
                                .frame(width: 48, height: 48)
                                .background(selectedInstagramFormat == format ? Color.kadroLime : Color.kadroCharcoal)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(format.rawValue)
                                    .font(.kadroBodyMedium)
                                    .foregroundColor(.kadroCharcoal)
                                Text(format.subtitle)
                                    .font(.kadroFootnote)
                                    .foregroundColor(.kadroWarmGray)
                            }
                            
                            Spacer()
                            
                            if selectedInstagramFormat == format {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.kadroLime)
                            }
                        }
                        .padding(16)
                        .background(Color.kadroSoftWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(selectedInstagramFormat == format ? Color.kadroLime : Color.kadroSand.opacity(0.65), lineWidth: selectedInstagramFormat == format ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if selectedInstagramFormat == .post {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Create.canvasType)
                        .font(.kadroTitle3)
                        .foregroundColor(.kadroCharcoal)
                    
                    HStack(spacing: 12) {
                        ForEach(InstagramPostCanvas.allCases) { canvas in
                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                    selectedPostCanvas = canvas
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(canvas.displayName)
                                        .font(.kadroBodyMedium)
                                        .foregroundColor(.kadroCharcoal)
                                    Text(canvas.subtitle)
                                        .font(.kadroFootnote)
                                        .foregroundColor(.kadroWarmGray)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
                                .background(Color.kadroSoftWhite)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(selectedPostCanvas == canvas ? Color.kadroLime : Color.kadroSand.opacity(0.65), lineWidth: selectedPostCanvas == canvas ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else if selectedInstagramFormat == .carousel {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Create.slideCount)
                        .font(.kadroTitle3)
                        .foregroundColor(.kadroCharcoal)

                    Text(L10n.Create.slideCountHint)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                    
                    FlowLayout(spacing: 10) {
                        ForEach(carouselSlideOptions, id: \.self) { count in
                            KadroChip(title: "\(count)", isSelected: selectedCarouselSlideCount == count) {
                                selectedCarouselSlideCount = count
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 3
    
    private var ideaStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                eyebrow: L10n.Create.stepEyebrow(3),
                title: ideaStepTitle,
                subtitle: L10n.Create.step3Subtitle
            )

            ideaEditorSection(
                title: L10n.Create.ideaInputLabel,
                placeholder: ideaPlaceholder
            )
            
            voiceRecorderCard
        }
    }
    
    private var voiceRecorderCard: some View {
        KadroCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Create.voiceInputTitle)
                            .font(.kadroBodyMedium)
                            .foregroundColor(.kadroCharcoal)
                        Text(voiceRecorder.isRecording ? L10n.Create.voiceInputRecordingHint : L10n.Create.voiceInputHint)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                    }
                    Spacer()
                    KadroStatusBadge(
                        title: voiceRecorder.isRecording ? "REC" : formattedDuration(voiceRecorder.currentDuration),
                        color: voiceRecorder.isRecording ? .red : .kadroLime
                    )
                }
                
                HStack(spacing: 12) {
                    Button {
                        Task {
                            if voiceRecorder.isRecording {
                                voiceRecorder.stopRecording()
                            } else {
                                lastTranscription = nil
                                lastTranscribedRecordingIdentifier = nil
                                await voiceRecorder.startRecording()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: voiceRecorder.isRecording ? "stop.fill" : "mic.fill")
                            Text(voiceRecorder.isRecording ? L10n.Create.voiceStop : L10n.Create.voiceRecord)
                        }
                        .font(.kadroButton)
                        .foregroundColor(voiceRecorder.isRecording ? .kadroSoftWhite : .kadroCharcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(voiceRecorder.isRecording ? Color.kadroCharcoal : Color.kadroLime)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isTranscribingVoiceNote)
                    
                    if voiceRecorder.completedRecordingURL != nil && !voiceRecorder.isRecording {
                        Button {
                            resetVoiceNoteState()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.kadroCharcoal)
                                .frame(width: 54, height: 54)
                                .background(Color.kadroIvory)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(isTranscribingVoiceNote)
                    }
                }
                
                if isTranscribingVoiceNote {
                    Text(L10n.Create.voiceTranscribing)
                        .font(.kadroCaption)
                        .foregroundColor(.kadroWarmGray)
                } else if let lastTranscription {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Create.voiceRecognized(lastTranscription.model))
                            .font(.kadroCaption)
                            .foregroundColor(.kadroWarmGray)
                        if lastTranscription.fallbackUsed == true {
                            Text(lastTranscription.fallbackReason ?? "")
                                .font(.kadroCaption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
    }
    
    private func ideaEditorSection(title: String, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.kadroFootnote)
                .foregroundColor(.kadroWarmGray)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .font(.kadroBody)
                    .foregroundColor(.kadroCharcoal)
                    .frame(minHeight: 220)
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .background(Color.kadroSoftWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.kadroSand, lineWidth: 1)
                    )
                
                if inputText.isEmpty {
                    Text(placeholder)
                        .font(.kadroBody)
                        .foregroundColor(.kadroWarmGray.opacity(0.72))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 24)
                        .allowsHitTesting(false)
                }
            }
            
            HStack {
                Text(L10n.Create.charCount(inputText.count))
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
                Spacer()
                if lastTranscription != nil {
                    Text(L10n.Create.voiceAdded)
                        .font(.kadroCaption)
                        .foregroundColor(.kadroLime)
                }
            }
        }
    }
    
    // MARK: - Step 4
    
    private var refineStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                eyebrow: L10n.Create.stepEyebrow(4),
                title: L10n.Create.step4Title,
                subtitle: L10n.Create.step4Subtitle
            )
            
            KadroCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.Create.yourChoices)
                        .font(.kadroFootnote)
                        .foregroundColor(.kadroWarmGray)
                    
                    FlowLayout(spacing: 8) {
                        summaryChip("Instagram")
                        summaryChip(selectedContentLanguage)
                        if let selectedInstagramFormat {
                            summaryChip(selectedInstagramFormat.rawValue)
                        }
                        if selectedInstagramFormat == .post {
                            summaryChip(selectedPostCanvas.displayName + " " + selectedPostCanvas.aspectRatio)
                        }
                        if selectedInstagramFormat == .carousel {
                            summaryChip(L10n.Create.slidesCount(selectedCarouselSlideCount))
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.Create.toneLabel)
                    .font(.kadroTitle3)
                    .foregroundColor(.kadroCharcoal)
                FlowLayout(spacing: 8) {
                    ForEach(ContentTone.allCases) { tone in
                        KadroChip(title: tone.displayName, isSelected: selectedTone == tone) {
                            selectedTone = selectedTone == tone ? nil : tone
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.Create.goalLabel)
                    .font(.kadroTitle3)
                    .foregroundColor(.kadroCharcoal)
                FlowLayout(spacing: 8) {
                    ForEach(ContentGoal.allCases) { goal in
                        KadroChip(title: goal.displayName, isSelected: selectedGoal == goal) {
                            selectedGoal = selectedGoal == goal ? nil : goal
                        }
                    }
                }
            }
            
            stylePackPickerSection
        }
    }
    
    private func summaryChip(_ title: String) -> some View {
        Text(title)
            .font(.kadroChip)
            .foregroundColor(.kadroCharcoal)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.kadroIvory)
            .clipShape(Capsule())
    }
    
    private var stylePackPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Create.visualStyle)
                .font(.kadroTitle3)
                .foregroundColor(.kadroCharcoal)

            Text(L10n.Create.visualStyleHint)
                .font(.kadroCallout)
                .foregroundColor(.kadroWarmGray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stylePacks, id: \.id) { pack in
                        Button {
                            selectedStylePackID = pack.id
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(pack.displayName)
                                    .font(.kadroBodyMedium)
                                    .foregroundColor(.kadroCharcoal)
                                Text(pack.shortDescription)
                                    .font(.kadroFootnote)
                                    .foregroundColor(.kadroWarmGray)
                                    .lineLimit(3)
                                Text("Refs: \(StylePackReferenceLoader.referenceCount(for: pack.id))")
                                    .font(.kadroCaption)
                                    .foregroundColor(.kadroWarmGray)
                            }
                            .padding(14)
                            .frame(width: 224, alignment: .leading)
                            .background(Color.kadroSoftWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(selectedStylePackID == pack.id ? Color.kadroLime : Color.kadroSand.opacity(0.65), lineWidth: selectedStylePackID == pack.id ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack(spacing: 12) {
            if currentStep != .service {
                KadroSecondaryButton(title: L10n.Create.back) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        if let previous = CreateStep(rawValue: currentStep.rawValue - 1) {
                            currentStep = previous
                        }
                    }
                }
                .disabled(isBusy)
            }
            
            KadroPrimaryButton(title: primaryButtonTitle) {
                handlePrimaryAction()
            }
            .disabled(!canContinue)
            .opacity(canContinue ? 1 : 0.55)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.kadroIvory
                .shadow(color: .black.opacity(0.06), radius: 12, y: -4)
        )
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.16)
                .ignoresSafeArea()
            
            KadroCard {
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(.kadroCharcoal)
                    Text(loadingTitle)
                        .font(.kadroTitle3)
                        .foregroundColor(.kadroCharcoal)
                    Text(loadingSubtitle)
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
    
    // MARK: - Actions
    
    private func handleServiceSelection(_ service: CreateService) {
        if service.isAvailable {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                selectedService = service
            }
        } else {
            appErrorMessage = L10n.Create.serviceUnavailable
        }
    }
    
    private func handlePrimaryAction() {
        guard !isBusy else { return }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            if let next = CreateStep(rawValue: currentStep.rawValue + 1) {
                currentStep = next
            } else {
                Task {
                    await generateContent()
                }
            }
        }
    }
    
    @MainActor
    private func transcribeVoiceNote(from url: URL) async {
        isTranscribingVoiceNote = true
        appErrorMessage = nil
        
        do {
            let response = try await transcriptionService.transcribe(audioURL: url, languageHint: selectedContentLanguage)
            mergeTranscript(response.transcript)
            lastTranscription = response
            lastTranscribedRecordingIdentifier = url.lastPathComponent
        } catch {
            appErrorMessage = error.localizedDescription
        }
        
        isTranscribingVoiceNote = false
    }
    
    private func mergeTranscript(_ transcript: String) {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else { return }
        let current = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if current.isEmpty {
            inputText = trimmedTranscript
        } else if !current.contains(trimmedTranscript) {
            inputText = current + "\n\n" + trimmedTranscript
        }
    }
    
    @MainActor
    private func generateContent() async {
        guard let outputType = resolvedOutputType else { return }
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        isGenerating = true
        appErrorMessage = nil
        
        let context = KadroGenerationContext(
            inputSource: lastTranscription == nil ? "Typed idea" : "Voice + Text",
            rawInput: trimmedInput,
            outputType: outputType,
            tone: selectedTone,
            goal: selectedGoal,
            platform: .instagram,
            contentLanguage: selectedContentLanguage,
            formatDetail: resolvedFormatDetail,
            preferredImageAspectRatio: resolvedPreferredImageAspectRatio,
            desiredSlideCount: resolvedDesiredSlideCount,
            brandProfile: profiles.first
        )
        
        do {
            let payload = try await aiService.generateContent(context: context)
            let project = ContentProject.makeFromGeneration(context: context, payload: payload)
            project.selectedStylePackID = selectedStylePackID
            project.selectedStylePackName = StylePackLibrary.pack(for: selectedStylePackID)?.displayName
            modelContext.insert(project)
            try modelContext.save()
            latestResult = GeneratedContentResult(project: project, payload: payload)
            appState.selectedTab = .content
            resetFlow()
        } catch {
            appErrorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    private func applyDraftIfNeeded() {
        if selectedStylePackID.isEmpty {
            selectedStylePackID = stylePacks.first?.id ?? ""
        }
        selectedContentLanguage = defaultContentLanguage
        
        guard let draft = appState.consumeCreateDraft() else { return }
        selectedService = .instagram
        
        if let outputType = draft.outputType {
            switch outputType {
            case .post:
                selectedInstagramFormat = .post
            case .carousel:
                selectedInstagramFormat = .carousel
            case .stories:
                selectedInstagramFormat = .story
            case .reels, .contentPack:
                selectedInstagramFormat = nil
            }
        }
        
        if !draft.seedText.isEmpty {
            inputText = draft.seedText
        }
        
        if selectedService != nil, selectedInstagramFormat != nil, !inputText.isEmpty {
            currentStep = .refine
        } else if selectedService != nil, selectedInstagramFormat != nil {
            currentStep = .idea
        } else if selectedService != nil {
            currentStep = .format
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration.rounded())
        return String(format: "%01d:%02d", seconds / 60, seconds % 60)
    }
    
    private func resetVoiceNoteState() {
        voiceRecorder.discardRecording()
        lastTranscription = nil
        lastTranscribedRecordingIdentifier = nil
        isTranscribingVoiceNote = false
    }
    
    private func resetFlow() {
        currentStep = .service
        selectedService = nil
        selectedContentLanguage = defaultContentLanguage
        selectedInstagramFormat = nil
        selectedPostCanvas = .portrait
        selectedCarouselSlideCount = 7
        inputText = ""
        selectedTone = nil
        selectedGoal = nil
        resetVoiceNoteState()
    }
    
    private func stepHeader(eyebrow: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(.kadroCaption)
                .foregroundColor(.kadroWarmGray)
            Text(title)
                .font(.kadroTitle)
                .foregroundColor(.kadroCharcoal)
            Text(subtitle)
                .font(.kadroCallout)
                .foregroundColor(.kadroWarmGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var ideaStepTitle: String {
        switch selectedInstagramFormat {
        case .post: return L10n.Create.ideaPostTitle
        case .story: return L10n.Create.ideaStoryTitle
        case .carousel: return L10n.Create.ideaCarouselTitle
        case .none: return L10n.Create.ideaGenericTitle
        }
    }

    private var ideaPlaceholder: String {
        switch selectedInstagramFormat {
        case .post: return L10n.Create.ideaPostPlaceholder
        case .story: return L10n.Create.ideaStoryPlaceholder
        case .carousel: return L10n.Create.ideaCarouselPlaceholder
        case .none: return L10n.Create.ideaGenericPlaceholder
        }
    }
}

#Preview {
    CreateFlowView()
        .environment(AppState())
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
