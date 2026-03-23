//
//  OnboardingView.swift
//  Kadro
//
//  5-screen onboarding: Value → Who are you → What to create → Your style → First win
//

import SwiftUI
import SwiftData

// MARK: - Onboarding State

@Observable
final class OnboardingState {
    var currentStep: Int = 0
    var selectedUserType: UserType? = nil
    var selectedContentGoals: Set<ContentGoalOption> = []
    var selectedTone: TonePreset = .balanced
    var selectedVisualMood: VisualMood = .minimal

    var canProceed: Bool {
        switch currentStep {
        case 1: return selectedUserType != nil
        case 2: return !selectedContentGoals.isEmpty
        default: return true
        }
    }

    enum TonePreset: String, CaseIterable, Identifiable {
        case friendly = "friendly"
        case expert = "expert"
        case balanced = "balanced"
        case bold = "bold"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .friendly: return L10n.Onboarding.toneFriendly
            case .expert:   return L10n.Onboarding.toneExpert
            case .balanced: return L10n.Onboarding.toneBalanced
            case .bold:     return L10n.Onboarding.toneBold
            }
        }

        var icon: String {
            switch self {
            case .friendly: return "heart"
            case .expert: return "graduationcap"
            case .balanced: return "scale.3d"
            case .bold: return "bolt"
            }
        }
    }

    enum ContentGoalOption: String, CaseIterable, Identifiable, Hashable {
        case posts = "posts"
        case carousels = "carousels"
        case reels = "reels"
        case contentPlan = "contentPlan"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .posts:       return L10n.Onboarding.goalPosts
            case .carousels:   return L10n.Onboarding.goalCarousels
            case .reels:       return L10n.Onboarding.goalReels
            case .contentPlan: return L10n.Onboarding.goalContentPlan
            }
        }

        var icon: String {
            switch self {
            case .posts: return "text.quote"
            case .carousels: return "rectangle.split.3x1"
            case .reels: return "video"
            case .contentPlan: return "calendar"
            }
        }
    }
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var onboardingState = OnboardingState()

    private let totalSteps = 4 // steps 0–3 show progress; step 4 = finish

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.kadroIvory.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots (shown for steps 0–3)
                progressDots
                    .padding(.top, 20)
                    .padding(.bottom, 4)
                    .opacity(onboardingState.currentStep < 4 ? 1 : 0)

                // Step content
                TabView(selection: $onboardingState.currentStep) {
                    OnboardingStep1()
                        .tag(0)
                    OnboardingStep2(state: onboardingState)
                        .tag(1)
                    OnboardingStep3(state: onboardingState)
                        .tag(2)
                    OnboardingStep4(state: onboardingState)
                        .tag(3)
                    OnboardingStep5(onFinish: completeOnboarding)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: onboardingState.currentStep)
                .ignoresSafeArea(edges: .bottom)
            }

            // Navigation buttons (shown for steps 0–3)
            if onboardingState.currentStep < 4 {
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .background(
                        LinearGradient(
                            colors: [Color.kadroIvory.opacity(0), Color.kadroIvory],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        .allowsHitTesting(false),
                        alignment: .bottom
                    )
            }
        }
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == onboardingState.currentStep ? Color.kadroLime : Color.kadroSand)
                    .frame(width: index == onboardingState.currentStep ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4), value: onboardingState.currentStep)
            }
        }
    }

    // MARK: - Navigation buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Back button (not on step 0)
            if onboardingState.currentStep > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onboardingState.currentStep -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.kadroCharcoal)
                        .frame(width: 52, height: 52)
                        .background(Color.kadroSoftWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.kadroSand, lineWidth: 1)
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Continue / Skip button
            Button {
                withAnimation(.easeInOut(duration: 0.35)) {
                    onboardingState.currentStep += 1
                }
            } label: {
                Text(onboardingState.currentStep == 0 ? L10n.Onboarding.start : L10n.Onboarding.continueAction)
                    .font(.kadroButton)
                    .foregroundColor(.kadroCharcoal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(onboardingState.canProceed ? Color.kadroLime : Color.kadroSand)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!onboardingState.canProceed && onboardingState.currentStep != 0)
            .animation(.spring(response: 0.3), value: onboardingState.canProceed)
        }
    }

    // MARK: - Finish

    private func completeOnboarding() {
        saveBrandProfile()
        withAnimation(.spring(response: 0.5)) {
            appState.hasCompletedOnboarding = true
        }
    }

    private func saveBrandProfile() {
        let profile = BrandProfile()
        if let userType = onboardingState.selectedUserType {
            profile.userType = userType
        }
        switch onboardingState.selectedTone {
        case .friendly:
            profile.toneWarmStrict = 0.1
            profile.toneBoldNeutral = 0.5
        case .expert:
            profile.toneExpertSimple = 0.1
            profile.toneBoldNeutral = 0.3
        case .balanced:
            break
        case .bold:
            profile.toneBoldNeutral = 0.1
            profile.toneExpertSimple = 0.2
        }
        profile.visualMood = onboardingState.selectedVisualMood
        modelContext.insert(profile)
    }
}

// MARK: - Step 1: Value proposition

private struct OnboardingStep1: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {
                // App icon block
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.kadroCharcoal)
                        .frame(width: 96, height: 96)

                    Image(systemName: "square.on.square.squareshape.controlhandles")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.kadroLime)
                }

                VStack(spacing: 12) {
                    Text("Kadro")
                        .font(.kadroLargeTitle)
                        .foregroundColor(.kadroCharcoal)

                    Text(L10n.Onboarding.step1Headline)
                        .font(.kadroTitle2)
                        .foregroundColor(.kadroCharcoal)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text(L10n.Onboarding.step1Subtitle)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // Feature list
                VStack(spacing: 10) {
                    OnboardingFeatureRow(icon: "bolt.fill", text: L10n.Onboarding.feature1)
                    OnboardingFeatureRow(icon: "paintbrush.pointed.fill", text: L10n.Onboarding.feature2)
                    OnboardingFeatureRow(icon: "rectangle.split.3x1.fill", text: L10n.Onboarding.feature3)
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 120)
        }
    }
}

// MARK: - Step 2: Who are you?

private struct OnboardingStep2: View {
    var state: OnboardingState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer().frame(height: 8)

                VStack(spacing: 8) {
                    Text(L10n.Onboarding.step2Title)
                        .font(.kadroLargeTitle)
                        .foregroundColor(.kadroCharcoal)

                    Text(L10n.Onboarding.step2Subtitle)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    ForEach(UserType.allCases) { userType in
                        OnboardingSelectionCard(
                            icon: userType.icon,
                            title: userType.displayName,
                            isSelected: state.selectedUserType == userType
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                state.selectedUserType = userType
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 100)
            }
        }
    }
}

// MARK: - Step 3: What to create?

private struct OnboardingStep3: View {
    var state: OnboardingState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer().frame(height: 8)

                VStack(spacing: 8) {
                    Text(L10n.Onboarding.step3Title)
                        .font(.kadroLargeTitle)
                        .foregroundColor(.kadroCharcoal)
                        .multilineTextAlignment(.center)

                    Text(L10n.Onboarding.step3Subtitle)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(OnboardingState.ContentGoalOption.allCases) { goal in
                        let isSelected = state.selectedContentGoals.contains(goal)
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                if isSelected {
                                    state.selectedContentGoals.remove(goal)
                                } else {
                                    state.selectedContentGoals.insert(goal)
                                }
                            }
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: goal.icon)
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(isSelected ? .kadroCharcoal : .kadroWarmGray)

                                Text(goal.displayName)
                                    .font(.kadroChip)
                                    .foregroundColor(isSelected ? .kadroCharcoal : .kadroWarmGray)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 110)
                            .background(isSelected ? Color.kadroLime : Color.kadroSoftWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(isSelected ? Color.clear : Color.kadroSand, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 100)
            }
        }
    }
}

// MARK: - Step 4: Your style

private struct OnboardingStep4: View {
    var state: OnboardingState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer().frame(height: 8)

                VStack(spacing: 8) {
                    Text(L10n.Onboarding.step4Title)
                        .font(.kadroLargeTitle)
                        .foregroundColor(.kadroCharcoal)

                    Text(L10n.Onboarding.step4Subtitle)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Onboarding.toneVoice)
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroCharcoal)
                        .padding(.horizontal, 24)

                    VStack(spacing: 10) {
                        ForEach(OnboardingState.TonePreset.allCases) { tone in
                            OnboardingSelectionCard(
                                icon: tone.icon,
                                title: tone.displayName,
                                isSelected: state.selectedTone == tone
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    state.selectedTone = tone
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Onboarding.visualStyle)
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroCharcoal)
                        .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(VisualMood.allCases) { mood in
                                let isSelected = state.selectedVisualMood == mood
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        state.selectedVisualMood = mood
                                    }
                                } label: {
                                    Text(mood.displayName)
                                        .font(.kadroChip)
                                        .foregroundColor(isSelected ? .kadroCharcoal : .kadroWarmGray)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(isSelected ? Color.kadroLime : Color.kadroSoftWhite)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(isSelected ? Color.clear : Color.kadroSand, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer().frame(height: 100)
            }
        }
    }
}

// MARK: - Step 5: First win

private struct OnboardingStep5: View {
    let onFinish: () -> Void
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(Color.kadroLime.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isPulsing ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: isPulsing)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.kadroLime)
                }
                .onAppear { isPulsing = true }

                VStack(spacing: 12) {
                    Text(L10n.Onboarding.step5Title)
                        .font(.kadroLargeTitle)
                        .foregroundColor(.kadroCharcoal)

                    Text(L10n.Onboarding.step5Subtitle)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                KadroPrimaryButton(title: L10n.Onboarding.createFirstContent, action: onFinish)

                Text(L10n.Onboarding.disclaimer)
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Reusable subcomponents

private struct OnboardingFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.kadroLime)
                .frame(width: 32, height: 32)
                .background(Color.kadroCharcoal)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(text)
                .font(.kadroCallout)
                .foregroundColor(.kadroCharcoal)

            Spacer()
        }
        .padding(14)
        .background(Color.kadroSoftWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct OnboardingSelectionCard: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .kadroCharcoal : .kadroWarmGray)
                    .frame(width: 42, height: 42)
                    .background(isSelected ? Color.kadroLime : Color.kadroSand.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(title)
                    .font(.kadroBodyMedium)
                    .foregroundColor(.kadroCharcoal)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.kadroLime)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(isSelected ? Color.kadroCharcoal.opacity(0.04) : Color.kadroSoftWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.kadroCharcoal.opacity(0.12) : Color.kadroSand, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(AppState())
        .modelContainer(for: [BrandProfile.self], inMemory: true)
}
