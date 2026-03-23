//
//  CreateFlowView.swift
//  Kadro
//
//  Create tab — guided 3-step creation flow
//

import SwiftUI
import SwiftData

// MARK: - Create Flow Steps

enum CreateStep: Int, CaseIterable {
    case inputSource = 0
    case enterContent = 1
    case chooseOutput = 2
    
    var title: String {
        switch self {
        case .inputSource: return "Источник"
        case .enterContent: return "Идея"
        case .chooseOutput: return "Формат"
        }
    }
}

// MARK: - Input Source

enum InputSource: String, CaseIterable, Identifiable {
    case topic = "Идея или тема"
    case bullets = "Тезисы"
    case voiceNote = "Голосовая заметка"
    case textOrLink = "Текст или ссылка"
    case oldPost = "Старый пост"
    case bestContent = "Лучший контент"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .topic: return "lightbulb"
        case .bullets: return "list.bullet"
        case .voiceNote: return "mic"
        case .textOrLink: return "doc.text"
        case .oldPost: return "arrow.counterclockwise"
        case .bestContent: return "star"
        }
    }
    
    var subtitle: String {
        switch self {
        case .topic: return "Опишите тему в свободной форме"
        case .bullets: return "Перечислите основные мысли"
        case .voiceNote: return "Запишите голосом — мы расшифруем в editable текст"
        case .textOrLink: return "Вставьте готовый текст"
        case .oldPost: return "Переработайте существующий"
        case .bestContent: return "Начните с лучшего примера"
        }
    }
}

struct CreateFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BrandProfile]
    
    @StateObject private var voiceRecorder = VoiceNoteRecorder()
    
    @State private var currentStep: CreateStep = .inputSource
    @State private var selectedSource: InputSource?
    @State private var inputText: String = ""
    @State private var selectedOutputType: ContentType = .post
    @State private var selectedTone: ContentTone?
    @State private var selectedGoal: ContentGoal?
    @State private var isGenerating = false
    @State private var isTranscribingVoiceNote = false
    @State private var appErrorMessage: String?
    @State private var latestResult: GeneratedContentResult?
    @State private var lastTranscribedRecordingIdentifier: String?
    @State private var lastTranscription: KadroVoiceTranscriptionResponse?
    
    private let aiService = KadroAIService()
    private let transcriptionService = KadroVoiceTranscriptionService()
    
    private var primaryButtonTitle: String {
        currentStep == .chooseOutput ? "Создать" : "Далее"
    }
    
    private var canContinue: Bool {
        switch currentStep {
        case .inputSource:
            return selectedSource != nil
        case .enterContent:
            return !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTranscribingVoiceNote
        case .chooseOutput:
            return !isGenerating
        }
    }
    
    private var isBusy: Bool {
        isGenerating || isTranscribingVoiceNote
    }
    
    private var loadingTitle: String {
        if isTranscribingVoiceNote {
            return "Расшифровываем заметку"
        }
        return "Генерируем контент"
    }
    
    private var loadingSubtitle: String {
        if isTranscribingVoiceNote {
            return "Переводим аудио в чистый editable текст, чтобы дальше собрать structured content package."
        }
        return "Собираем structured result, учитываем brand memory и подготавливаем publish-ready draft."
    }
    
    private var transcriptionLanguageHint: String {
        profiles.first?.language ?? "Русский"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case .inputSource:
                            inputSourceStep
                        case .enterContent:
                            enterContentStep
                        case .chooseOutput:
                            chooseOutputStep
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
                .background(Color.kadroIvory)
            }
            .background(Color.kadroIvory)
            .navigationTitle("Создать")
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .sheet(item: $latestResult) { result in
                GeneratedContentView(result: result)
            }
            .alert(
                "Что-то пошло не так",
                isPresented: Binding(
                    get: { appErrorMessage != nil },
                    set: { if !$0 { appErrorMessage = nil } }
                ),
                actions: {
                    Button("Ок", role: .cancel) {
                        appErrorMessage = nil
                    }
                },
                message: {
                    Text(appErrorMessage ?? "Попробуйте ещё раз.")
                }
            )
            .overlay {
                if isBusy {
                    loadingOverlay
                }
            }
            .onChange(of: selectedSource) { _, newValue in
                guard newValue != .voiceNote else { return }
                resetVoiceNoteState(keepTranscript: false)
            }
            .onChange(of: voiceRecorder.completedRecordingURL) { _, newValue in
                guard let newValue, selectedSource == .voiceNote else { return }
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
    
    // MARK: - Progress Bar
    
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
    
    // MARK: - Step 1: Input Source
    
    private var inputSourceStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("С чего начнём?")
                .font(.kadroTitle)
                .foregroundColor(.kadroCharcoal)
            
            Text("Выберите, как вы хотите начать создание контента")
                .font(.kadroCallout)
                .foregroundColor(.kadroWarmGray)
            
            VStack(spacing: 10) {
                ForEach(InputSource.allCases) { source in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedSource = source
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: source.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(selectedSource == source ? .kadroCharcoal : .kadroLime)
                                .frame(width: 44, height: 44)
                                .background(selectedSource == source ? Color.kadroLime : Color.kadroCharcoal)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.rawValue)
                                    .font(.kadroBodyMedium)
                                    .foregroundColor(.kadroCharcoal)
                                
                                Text(source.subtitle)
                                    .font(.kadroFootnote)
                                    .foregroundColor(.kadroWarmGray)
                            }
                            
                            Spacer()
                            
                            if selectedSource == source {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.kadroLime)
                                    .font(.system(size: 22))
                            }
                        }
                        .padding(14)
                        .background(Color.kadroSoftWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(selectedSource == source ? Color.kadroLime : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Enter Content
    
    private var enterContentStep: some View {
        Group {
            if selectedSource == .voiceNote {
                voiceNoteStep
            } else {
                textInputStep
            }
        }
    }
    
    private var textInputStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("О чём будет контент?")
                .font(.kadroTitle)
                .foregroundColor(.kadroCharcoal)
            
            Text("Опишите свою идею — мы поможем превратить её в готовый контент")
                .font(.kadroCallout)
                .foregroundColor(.kadroWarmGray)
            
            ideaEditorSection(
                title: nil,
                placeholder: "Например: хочу пост для экспертов о том, почему личный бренд не должен звучать как реклама"
            )
            
            suggestionChips
        }
    }
    
    private var voiceNoteStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Запишите голосовую заметку")
                .font(.kadroTitle)
                .foregroundColor(.kadroCharcoal)
            
            Text("Запишите мысль вслух. Мы расшифруем её в editable текст и используем для генерации контента.")
                .font(.kadroCallout)
                .foregroundColor(.kadroWarmGray)
            
            KadroCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(voiceRecorder.isRecording ? "Идёт запись" : "Голосовая заметка")
                                .font(.kadroBodyMedium)
                                .foregroundColor(.kadroCharcoal)
                            Text(voiceRecorder.isRecording ? "Говорите свободно — идея не должна быть идеальной" : "До 90 секунд. После остановки начнём транскрибацию автоматически.")
                                .font(.kadroCallout)
                                .foregroundColor(.kadroWarmGray)
                        }
                        Spacer()
                        KadroStatusBadge(
                            title: voiceRecorder.isRecording ? "REC" : formattedDuration(voiceRecorder.currentDuration),
                            color: voiceRecorder.isRecording ? .kadroError : .kadroLime
                        )
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                if voiceRecorder.isRecording {
                                    voiceRecorder.stopRecording()
                                } else {
                                    inputText = ""
                                    lastTranscription = nil
                                    lastTranscribedRecordingIdentifier = nil
                                    await voiceRecorder.startRecording()
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: voiceRecorder.isRecording ? "stop.fill" : "mic.fill")
                                Text(voiceRecorder.isRecording ? "Остановить" : "Начать запись")
                            }
                            .font(.kadroButton)
                            .foregroundColor(voiceRecorder.isRecording ? .kadroSoftWhite : .kadroCharcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(voiceRecorder.isRecording ? Color.kadroCharcoal : Color.kadroLime)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(isTranscribingVoiceNote)
                        
                        if voiceRecorder.completedRecordingURL != nil && !voiceRecorder.isRecording {
                            Button {
                                resetVoiceNoteState(keepTranscript: false)
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.kadroCharcoal)
                                    .frame(width: 54, height: 54)
                                    .background(Color.kadroIvory)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .disabled(isTranscribingVoiceNote)
                        }
                    }
                    
                    if let lastTranscription {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Транскрибация: \(lastTranscription.model)")
                                .font(.kadroCaption)
                                .foregroundColor(.kadroWarmGray)
                            if lastTranscription.fallbackUsed == true {
                                Text(lastTranscription.fallbackReason ?? "Включился fallback-маршрут транскрибации")
                                    .font(.kadroCaption)
                                    .foregroundColor(.kadroWarning)
                            }
                        }
                    } else if voiceRecorder.completedRecordingURL != nil && !voiceRecorder.isRecording && !isTranscribingVoiceNote {
                        Button("Повторить транскрибацию") {
                            guard let url = voiceRecorder.completedRecordingURL else { return }
                            Task {
                                await transcribeVoiceNote(from: url)
                            }
                        }
                        .font(.kadroFootnote)
                        .foregroundColor(.kadroCharcoal)
                    }
                }
            }
            
            ideaEditorSection(
                title: "Расшифровка",
                placeholder: "После записи здесь появится transcript. Вы сможете отредактировать его перед генерацией."
            )
            
            suggestionChips
        }
    }
    
    private func ideaEditorSection(title: String?, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.kadroFootnote)
                    .foregroundColor(.kadroWarmGray)
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .font(.kadroBody)
                    .foregroundColor(.kadroCharcoal)
                    .frame(minHeight: 170)
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .background(Color.kadroSoftWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.kadroSand, lineWidth: 1)
                    )
                
                if inputText.isEmpty {
                    Text(placeholder)
                        .font(.kadroBody)
                        .foregroundColor(.kadroWarmGray.opacity(0.7))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 24)
                        .allowsHitTesting(false)
                }
            }
            
            HStack {
                Text("\(inputText.count) символов")
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
                Spacer()
                if selectedSource == .voiceNote, let completedRecordingURL = voiceRecorder.completedRecordingURL {
                    Text(completedRecordingURL.lastPathComponent)
                        .font(.kadroCaption)
                        .foregroundColor(.kadroWarmGray)
                        .lineLimit(1)
                }
            }
        }
    }
    
    private var suggestionChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Подсказки")
                .font(.kadroFootnote)
                .foregroundColor(.kadroWarmGray)
            
            FlowLayout(spacing: 8) {
                ForEach(["Обучающий", "Личный", "Продающий", "Экспертный", "Вовлекающий"], id: \.self) { chip in
                    KadroChip(title: chip, isSelected: false) {
                        inputText += inputText.isEmpty ? chip : ", \(chip)"
                    }
                }
            }
        }
    }
    
    // MARK: - Step 3: Choose Output
    
    private var chooseOutputStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Какой формат?")
                .font(.kadroTitle)
                .foregroundColor(.kadroCharcoal)
            
            Text("Выберите тип контента для генерации")
                .font(.kadroCallout)
                .foregroundColor(.kadroWarmGray)
            
            VStack(spacing: 10) {
                ForEach(ContentType.allCases) { type in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedOutputType = type
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: type.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(selectedOutputType == type ? .kadroCharcoal : .kadroLime)
                                .frame(width: 44, height: 44)
                                .background(selectedOutputType == type ? Color.kadroLime : Color.kadroCharcoal)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            Text(type.rawValue)
                                .font(.kadroBodyMedium)
                                .foregroundColor(.kadroCharcoal)
                            
                            Spacer()
                            
                            if selectedOutputType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.kadroLime)
                                    .font(.system(size: 22))
                            }
                        }
                        .padding(14)
                        .background(Color.kadroSoftWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(selectedOutputType == type ? Color.kadroLime : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Тон")
                    .font(.kadroTitle3)
                    .foregroundColor(.kadroCharcoal)
                
                FlowLayout(spacing: 8) {
                    ForEach(ContentTone.allCases) { tone in
                        KadroChip(title: tone.rawValue, isSelected: selectedTone == tone) {
                            selectedTone = selectedTone == tone ? nil : tone
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Цель")
                    .font(.kadroTitle3)
                    .foregroundColor(.kadroCharcoal)
                
                FlowLayout(spacing: 8) {
                    ForEach(ContentGoal.allCases) { goal in
                        KadroChip(title: goal.rawValue, isSelected: selectedGoal == goal) {
                            selectedGoal = selectedGoal == goal ? nil : goal
                        }
                    }
                }
            }
            
            KadroCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("AI routing")
                        .font(.kadroFootnote)
                        .foregroundColor(.kadroWarmGray)
                    Text("Основной text/understanding: google/gemini-3-flash-preview")
                        .font(.kadroCallout)
                        .foregroundColor(.kadroCharcoal)
                    Text("Транскрибация голосовых заметок: OpenRouter audio input → Supabase Edge Function")
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                    Text("Cheap ops: openai/gpt-5.4-nano · Image: google/gemini-3.1-flash-image-preview · Candidate: bytedance/seed-2.0-lite")
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                }
            }
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack(spacing: 12) {
            if currentStep != .inputSource {
                KadroSecondaryButton(title: "Назад") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        if let prev = CreateStep(rawValue: currentStep.rawValue - 1) {
                            currentStep = prev
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
            let response = try await transcriptionService.transcribe(audioURL: url, languageHint: transcriptionLanguageHint)
            inputText = response.transcript
            lastTranscription = response
            lastTranscribedRecordingIdentifier = url.lastPathComponent
        } catch {
            appErrorMessage = error.localizedDescription
        }
        
        isTranscribingVoiceNote = false
    }
    
    @MainActor
    private func generateContent() async {
        guard let selectedSource else { return }
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        isGenerating = true
        appErrorMessage = nil
        
        let context = KadroGenerationContext(
            inputSource: selectedSource.rawValue,
            rawInput: trimmedInput,
            outputType: selectedOutputType,
            tone: selectedTone,
            goal: selectedGoal,
            platform: selectedOutputType.defaultPlatform,
            brandProfile: profiles.first
        )
        
        do {
            let payload = try await aiService.generateContent(context: context)
            let project = ContentProject.makeFromGeneration(context: context, payload: payload)
            modelContext.insert(project)
            try modelContext.save()
            latestResult = GeneratedContentResult(project: project, payload: payload)
            resetFlow()
            appState.selectedTab = .content
        } catch {
            appErrorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    private func applyDraftIfNeeded() {
        guard let draft = appState.consumeCreateDraft() else { return }
        if let outputType = draft.outputType {
            selectedOutputType = outputType
        }
        if let source = draft.source {
            selectedSource = source
        }
        if !draft.seedText.isEmpty {
            inputText = draft.seedText
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration.rounded())
        return String(format: "%01d:%02d", seconds / 60, seconds % 60)
    }
    
    private func resetVoiceNoteState(keepTranscript: Bool) {
        voiceRecorder.discardRecording()
        lastTranscription = nil
        lastTranscribedRecordingIdentifier = nil
        isTranscribingVoiceNote = false
        if !keepTranscript {
            inputText = ""
        }
    }
    
    private func resetFlow() {
        currentStep = .inputSource
        selectedSource = nil
        inputText = ""
        selectedOutputType = .post
        selectedTone = nil
        selectedGoal = nil
        resetVoiceNoteState(keepTranscript: false)
    }
}

// MARK: - Flow Layout (simple wrapping layout)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    CreateFlowView()
        .environment(AppState())
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
