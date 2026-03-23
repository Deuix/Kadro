//
//  CreateFlowView.swift
//  Kadro
//
//  Editorial-style create flow with Bento grids and smooth Voice UI
//  Dark-mode adaptive
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
        case .square: return L10n.Create.canvasSquare + " (\(aspectRatio))"
        case .portrait: return L10n.Create.canvasPortrait + " (\(aspectRatio))"
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
    @Environment(\.colorScheme) private var colorScheme
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
    private let supportedContentLanguages = ["Русский", "English", "Türkçe", "Azərbaycan"]
    
    private var defaultContentLanguage: String {
        let candidate = profiles.first?.language.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return candidate.isEmpty ? "Русский" : candidate
    }
    
    private var resolvedOutputType: ContentType? {
        selectedInstagramFormat?.outputType
    }
    
    private var resolvedFormatDetail: String? {
        switch selectedInstagramFormat {
        case .post: return selectedPostCanvas.formatDetail
        case .story: return "instagram_story"
        case .carousel: return "instagram_carousel"
        case .none: return nil
        }
    }
    
    private var resolvedPreferredImageAspectRatio: String? {
        switch selectedInstagramFormat {
        case .post: return selectedPostCanvas.aspectRatio
        case .story: return "9:16"
        case .carousel: return "4:5"
        case .none: return nil
        }
    }
    
    private var resolvedDesiredSlideCount: Int? {
        selectedInstagramFormat == .carousel ? selectedCarouselSlideCount : nil
    }
    
    private var primaryButtonTitle: String {
        switch currentStep {
        case .service: return L10n.Create.continueAction
        case .format: return L10n.Create.continueAction
        case .idea: return L10n.Create.next
        case .refine: return L10n.Create.createGeneric
        }
    }
    
    private var canContinue: Bool {
        switch currentStep {
        case .service: return selectedService?.isAvailable == true
        case .format: return selectedInstagramFormat != nil
        case .idea: return !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTranscribingVoiceNote
        case .refine: return !isGenerating && !selectedStylePackID.isEmpty && resolvedOutputType != nil
        }
    }
    
    private var isBusy: Bool { isGenerating || isTranscribingVoiceNote }
    
    private var loadingTitle: String {
        isTranscribingVoiceNote ? L10n.Create.loadingVoiceTitle : L10n.Create.loadingContentTitle
    }
    
    private var loadingSubtitle: String {
        isTranscribingVoiceNote ? L10n.Create.loadingVoiceSubtitle : L10n.Create.loadingContentSubtitle
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 32) {
                        headerView
                        
                        switch currentStep {
                        case .service: serviceStep
                        case .format: formatStep
                        case .idea: ideaStep
                        case .refine: refineStep
                        }
                    }
                    .padding(.bottom, 140)
                }
                .background(Color.kadroBackground(for: colorScheme))
                
                bottomBar
            }
            .navigationBarHidden(true)
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
                    Button(L10n.Common.ok, role: .cancel) { appErrorMessage = nil }
                },
                message: { Text(appErrorMessage ?? L10n.Common.errorMessage) }
            )
            .overlay {
                if isBusy { loadingOverlay }
            }
            .onChange(of: voiceRecorder.completedRecordingURL) { _, newValue in
                guard let newValue else { return }
                let identifier = newValue.lastPathComponent
                guard lastTranscribedRecordingIdentifier != identifier else { return }
                Task { await transcribeVoiceNote(from: newValue) }
            }
            .onChange(of: voiceRecorder.lastErrorMessage) { _, newValue in
                guard let newValue else { return }
                appErrorMessage = newValue
            }
            .onAppear { applyDraftIfNeeded() }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Create.stepEyebrow(currentStep.rawValue + 1))
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.kadroSecondary(for: colorScheme))
                
                Text(currentStep.title)
                    .font(.custom("New York", size: 36).weight(.bold))
                    .foregroundColor(.kadroPrimary(for: colorScheme))
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
    
    // MARK: - Step 1: Service
    
    private var serviceStep: some View {
        VStack(spacing: 24) {
            // Language selector
            HStack {
                Text(L10n.Create.contentLanguage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.kadroSecondary(for: colorScheme))
                Spacer()
                Menu {
                    ForEach(supportedContentLanguages, id: \.self) { language in
                        Button(language) { selectedContentLanguage = language }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedContentLanguage)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.kadroPrimary(for: colorScheme))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.kadroPrimary(for: colorScheme))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.kadroCard(for: colorScheme))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 24)
            
            // Services Bento Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(CreateService.allCases) { service in
                    serviceCard(for: service)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func serviceCard(for service: CreateService) -> some View {
        let isSelected = selectedService == service
        let isAvailable = service.isAvailable
        
        return Button {
            if isAvailable { selectedService = service }
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Image(systemName: service.icon)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(isSelected ? Color.kadroBackground(for: colorScheme) : .kadroPrimary(for: colorScheme))
                    Spacer()
                    if !isAvailable {
                        Text(L10n.Create.serviceComingSoon)
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.kadroWarmGray)
                            .clipShape(Capsule())
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.kadroBackground(for: colorScheme))
                    }
                }
                Spacer()
                Text(service.rawValue)
                    .font(.custom("New York", size: 20).weight(.medium))
                    .foregroundColor(isSelected ? Color.kadroBackground(for: colorScheme) : .kadroPrimary(for: colorScheme))
            }
            .padding(16)
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.kadroPrimary(for: colorScheme) : Color.kadroCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.kadroBorderColor(for: colorScheme), lineWidth: isAvailable ? 0.5 : 0)
            )
            .opacity(isAvailable ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Step 2: Format
    
    private var formatStep: some View {
        VStack(spacing: 24) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(InstagramCreateFormat.allCases) { format in
                    formatCard(for: format)
                }
            }
            .padding(.horizontal, 24)
            
            if selectedInstagramFormat == .post {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Create.canvasType.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.kadroSecondary(for: colorScheme))
                        .padding(.horizontal, 24)
                    
                    HStack(spacing: 12) {
                        ForEach(InstagramPostCanvas.allCases) { canvas in
                            Button {
                                selectedPostCanvas = canvas
                            } label: {
                                Text(canvas.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedPostCanvas == canvas ? .kadroCharcoal : .kadroSecondary(for: colorScheme))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(selectedPostCanvas == canvas ? Color.kadroLime : Color.kadroCard(for: colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedPostCanvas == canvas ? Color.clear : Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            } else if selectedInstagramFormat == .carousel {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Create.slideCount.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.kadroSecondary(for: colorScheme))
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(carouselSlideOptions, id: \.self) { count in
                                Button {
                                    selectedCarouselSlideCount = count
                                } label: {
                                    Text("\(count)")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(selectedCarouselSlideCount == count ? .kadroCharcoal : .kadroSecondary(for: colorScheme))
                                        .frame(width: 48, height: 48)
                                        .background(selectedCarouselSlideCount == count ? Color.kadroLime : Color.kadroCard(for: colorScheme))
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(selectedCarouselSlideCount == count ? Color.clear : Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }
    
    private func formatCard(for format: InstagramCreateFormat) -> some View {
        let isSelected = selectedInstagramFormat == format
        
        return Button {
            selectedInstagramFormat = format
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: format.icon)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(isSelected ? Color.kadroBackground(for: colorScheme) : .kadroPrimary(for: colorScheme))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.kadroLime)
                    }
                }
                Spacer()
                Text(format.rawValue)
                    .font(.custom("New York", size: 20).weight(.medium))
                    .foregroundColor(isSelected ? Color.kadroBackground(for: colorScheme) : .kadroPrimary(for: colorScheme))
            }
            .padding(16)
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.kadroPrimary(for: colorScheme) : Color.kadroCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Step 3: Idea / Voice Editor
    
    private var ideaStep: some View {
        VStack(spacing: 24) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .font(.custom("New York", size: 22))
                    .foregroundColor(.kadroPrimary(for: colorScheme))
                    .lineSpacing(6)
                    .scrollContentBackground(.hidden)
                    .padding(20)
                    .frame(minHeight: 280)
                    .background(Color.kadroCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                
                if inputText.isEmpty && !voiceRecorder.isRecording {
                    Text(L10n.Create.ideaGenericPlaceholder)
                        .font(.custom("New York", size: 22))
                        .foregroundColor(.kadroSecondary(for: colorScheme).opacity(0.6))
                        .padding(28)
                        .allowsHitTesting(false)
                }
                
                if voiceRecorder.isRecording {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(L10n.Create.voiceListening)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Mic button
            HStack {
                Spacer()
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
                    ZStack {
                        if voiceRecorder.isRecording {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .scaleEffect(1.2)
                                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: voiceRecorder.isRecording)
                        }
                        Circle()
                            .fill(voiceRecorder.isRecording ? Color.red : Color.kadroPrimary(for: colorScheme))
                            .frame(width: 72, height: 72)
                        Image(systemName: voiceRecorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Color.kadroBackground(for: colorScheme))
                    }
                }
                .disabled(isTranscribingVoiceNote)
                Spacer()
            }
            
            if isTranscribingVoiceNote {
                Text(L10n.Create.voiceTranscribing)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.kadroSecondary(for: colorScheme))
            } else if let lastTranscription, lastTranscription.fallbackUsed == true {
                Text(L10n.Create.voiceFallbackModel)
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Step 4: Refine Details
    
    private var refineStep: some View {
        VStack(alignment: .leading, spacing: 32) {
            
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Create.toneLabel.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.kadroSecondary(for: colorScheme))
                    .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ContentTone.allCases) { tone in
                            Button {
                                selectedTone = selectedTone == tone ? nil : tone
                            } label: {
                                Text(tone.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedTone == tone ? .kadroCharcoal : .kadroSecondary(for: colorScheme))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(selectedTone == tone ? Color.kadroLime : Color.kadroCard(for: colorScheme))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(selectedTone == tone ? Color.clear : Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Create.goalLabel.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.kadroSecondary(for: colorScheme))
                    .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ContentGoal.allCases) { goal in
                            Button {
                                selectedGoal = selectedGoal == goal ? nil : goal
                            } label: {
                                Text(goal.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedGoal == goal ? .kadroCharcoal : .kadroSecondary(for: colorScheme))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(selectedGoal == goal ? Color.kadroLime : Color.kadroCard(for: colorScheme))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(selectedGoal == goal ? Color.clear : Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Create.visualStyle.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.kadroSecondary(for: colorScheme))
                    .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(stylePacks, id: \.id) { pack in
                            Button {
                                selectedStylePackID = pack.id
                            } label: {
                                ZStack(alignment: .bottomLeading) {
                                    stylePackColor(for: pack.id)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(pack.displayName)
                                            .font(.custom("New York", size: 16).weight(.bold))
                                            .foregroundColor(pack.id == "dark" ? .white : .kadroCharcoal)
                                        Text(pack.shortDescription)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor((pack.id == "dark" ? Color.white : Color.kadroCharcoal).opacity(0.8))
                                            .lineLimit(2)
                                    }
                                    .padding(16)
                                }
                                .frame(width: 160, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedStylePackID == pack.id ? Color.kadroLime : Color.kadroBorderColor(for: colorScheme), lineWidth: selectedStylePackID == pack.id ? 4 : 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 24)
        }
    }
    
    private func stylePackColor(for id: String) -> Color {
        switch id {
        case "minimalistic": return Color(red: 255/255, green: 253/255, blue: 248/255)
        case "elegant": return Color(red: 234/255, green: 226/255, blue: 210/255)
        case "dark": return Color(red: 23/255, green: 23/255, blue: 23/255)
        case "modern": return Color(red: 223/255, green: 230/255, blue: 236/255)
        case "texty": return Color(red: 247/255, green: 244/255, blue: 237/255)
        default: return Color(red: 221/255, green: 214/255, blue: 200/255)
        }
    }
    
    // MARK: - Floating Bottom Bar
    
    private var bottomBar: some View {
        VStack {
            HStack(spacing: 16) {
                if currentStep != .service {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if let previous = CreateStep(rawValue: currentStep.rawValue - 1) {
                                currentStep = previous
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.kadroPrimary(for: colorScheme))
                            .frame(width: 56, height: 56)
                            .background(Color.kadroCard(for: colorScheme))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                    }
                    .disabled(isBusy)
                }
                
                Button {
                    handlePrimaryAction()
                } label: {
                    Text(primaryButtonTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(canContinue ? .kadroCharcoal : .kadroSecondary(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(canContinue ? Color.kadroLime : Color.kadroCard(for: colorScheme))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(canContinue ? Color.clear : Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5))
                }
                .disabled(!canContinue || isBusy)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(Color.kadroBackground(for: colorScheme).opacity(0.95))
                    .ignoresSafeArea()
            )
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .backdropFilter()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.kadroPrimary(for: colorScheme))
                Text(loadingTitle)
                    .font(.custom("New York", size: 24).weight(.medium))
                    .foregroundColor(.kadroPrimary(for: colorScheme))
                Text(loadingSubtitle)
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
                Task { await generateContent() }
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
        if selectedStylePackID.isEmpty { selectedStylePackID = stylePacks.first?.id ?? "" }
        selectedContentLanguage = defaultContentLanguage
        
        guard let draft = appState.consumeCreateDraft() else { return }
        selectedService = .instagram
        
        if let outputType = draft.outputType {
            switch outputType {
            case .post: selectedInstagramFormat = .post
            case .carousel: selectedInstagramFormat = .carousel
            case .stories: selectedInstagramFormat = .story
            case .reels, .contentPack: selectedInstagramFormat = nil
            }
        }
        
        if !draft.seedText.isEmpty { inputText = draft.seedText }
        
        if selectedService != nil, selectedInstagramFormat != nil, !inputText.isEmpty {
            currentStep = .refine
        } else if selectedService != nil, selectedInstagramFormat != nil {
            currentStep = .idea
        } else if selectedService != nil {
            currentStep = .format
        }
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
}

// Custom View Modifier for blur
extension View {
    func backdropFilter() -> some View {
        if #available(iOS 15.0, *) {
            return self.background(.ultraThinMaterial)
        } else {
            return self
        }
    }
}

#Preview {
    CreateFlowView()
        .environment(AppState())
#if canImport(SwiftData)
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
#endif
}
