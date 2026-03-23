//
//  BrandView.swift
//  Kadro
//
//  Brand tab — brand memory settings (tone, style, writing rules)
//

import SwiftUI
import SwiftData

struct BrandView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BrandProfile]
    
    private var profile: BrandProfile? { profiles.first }
    
    @State private var brandName: String = ""
    @State private var niche: String = ""
    @State private var audience: String = ""
    @State private var selectedUserType: UserType?
    
    // Tone sliders
    @State private var toneExpertSimple: Float = 0.3
    @State private var toneWarmStrict: Float = 0.3
    @State private var toneBoldNeutral: Float = 0.4
    @State private var toneShortDetailed: Float = 0.5
    
    // Writing rules
    @State private var wordsToUse: String = ""
    @State private var wordsToAvoid: String = ""
    @State private var ctaStyle: String = ""
    @State private var favoritePhrases: String = ""
    
    // Visual
    @State private var selectedMood: VisualMood = .minimal
    
    @State private var hasLoaded = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    basicsSection
                    toneSection
                    writingRulesSection
                    visualStyleSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.kadroIvory)
            .navigationTitle("Бренд")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Сохранить") {
                        saveProfile()
                    }
                    .font(.kadroButton)
                    .foregroundColor(.kadroLime)
                }
            }
            .onAppear {
                if !hasLoaded {
                    loadProfile()
                    hasLoaded = true
                }
            }
        }
    }
    
    // MARK: - Basics Section
    
    private var basicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            KadroSectionHeader(title: "Основное")
            
            KadroCard {
                VStack(spacing: 14) {
                    brandTextField(title: "Название бренда", text: $brandName, placeholder: "Ваш бренд или имя")
                    brandTextField(title: "Ниша", text: $niche, placeholder: "Например: фитнес, маркетинг, психология")
                    brandTextField(title: "Аудитория", text: $audience, placeholder: "Кто ваша целевая аудитория?")
                }
            }
            
            // User type
            VStack(alignment: .leading, spacing: 10) {
                Text("Тип профиля")
                    .font(.kadroFootnote)
                    .foregroundColor(.kadroWarmGray)
                
                HStack(spacing: 10) {
                    ForEach(UserType.allCases) { type in
                        Button {
                            selectedUserType = type
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(selectedUserType == type ? .kadroCharcoal : .kadroLime)
                                
                                Text(type.rawValue)
                                    .font(.kadroCaption)
                                    .foregroundColor(selectedUserType == type ? .kadroCharcoal : .kadroWarmGray)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(selectedUserType == type ? Color.kadroLime : Color.kadroSoftWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Tone Section
    
    private var toneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            KadroSectionHeader(title: "Тон коммуникации")
            
            KadroCard {
                VStack(spacing: 18) {
                    toneSlider(
                        title: "Экспертность",
                        leftLabel: "Экспертный",
                        rightLabel: "Простой",
                        value: $toneExpertSimple
                    )
                    
                    toneSlider(
                        title: "Теплота",
                        leftLabel: "Тёплый",
                        rightLabel: "Строгий",
                        value: $toneWarmStrict
                    )
                    
                    toneSlider(
                        title: "Смелость",
                        leftLabel: "Смелый",
                        rightLabel: "Нейтральный",
                        value: $toneBoldNeutral
                    )
                    
                    toneSlider(
                        title: "Детальность",
                        leftLabel: "Кратко",
                        rightLabel: "Детально",
                        value: $toneShortDetailed
                    )
                }
            }
        }
    }
    
    // MARK: - Writing Rules Section
    
    private var writingRulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            KadroSectionHeader(title: "Правила текста")
            
            KadroCard {
                VStack(spacing: 14) {
                    brandTextField(title: "Часто использовать", text: $wordsToUse, placeholder: "Слова и фразы, которые вы любите")
                    brandTextField(title: "Избегать", text: $wordsToAvoid, placeholder: "Слова, которые не подходят бренду")
                    brandTextField(title: "Стиль CTA", text: $ctaStyle, placeholder: "Как вы призываете к действию?")
                    brandTextField(title: "Любимые фразы", text: $favoritePhrases, placeholder: "Фразы, которые вас характеризуют")
                }
            }
        }
    }
    
    // MARK: - Visual Style Section
    
    private var visualStyleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            KadroSectionHeader(title: "Визуальный стиль")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(VisualMood.allCases) { mood in
                        Button {
                            selectedMood = mood
                        } label: {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(moodColor(for: mood))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(selectedMood == mood ? Color.kadroLime : Color.clear, lineWidth: 3)
                                    )
                                
                                Text(mood.rawValue)
                                    .font(.kadroChip)
                                    .foregroundColor(selectedMood == mood ? .kadroCharcoal : .kadroWarmGray)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Reusable Components
    
    private func brandTextField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.kadroFootnote)
                .foregroundColor(.kadroWarmGray)
            
            TextField(placeholder, text: text)
                .font(.kadroBody)
                .foregroundColor(.kadroCharcoal)
                .padding(12)
                .background(Color.kadroIvory)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
    
    private func toneSlider(title: String, leftLabel: String, rightLabel: String, value: Binding<Float>) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.kadroFootnote)
                .foregroundColor(.kadroWarmGray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Slider(value: value, in: 0...1)
                .tint(.kadroLime)
            
            HStack {
                Text(leftLabel)
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
                Spacer()
                Text(rightLabel)
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func moodColor(for mood: VisualMood) -> Color {
        switch mood {
        case .minimal: return .kadroSoftWhite
        case .bold: return .kadroCharcoal
        case .editorial: return .kadroSand
        case .soft: return .kadroIvory
        case .premium: return .kadroCharcoal.opacity(0.8)
        }
    }
    
    private func loadProfile() {
        guard let p = profile else { return }
        brandName = p.brandName
        niche = p.niche
        audience = p.audience
        selectedUserType = p.userType
        toneExpertSimple = p.toneExpertSimple
        toneWarmStrict = p.toneWarmStrict
        toneBoldNeutral = p.toneBoldNeutral
        toneShortDetailed = p.toneShortDetailed
        wordsToUse = p.wordsToUse
        wordsToAvoid = p.wordsToAvoid
        ctaStyle = p.ctaStyle
        favoritePhrases = p.favoritePhrases
        selectedMood = p.visualMood
    }
    
    private func saveProfile() {
        let p: BrandProfile
        if let existing = profile {
            p = existing
        } else {
            p = BrandProfile()
            modelContext.insert(p)
        }
        
        p.brandName = brandName
        p.niche = niche
        p.audience = audience
        p.userType = selectedUserType
        p.toneExpertSimple = toneExpertSimple
        p.toneWarmStrict = toneWarmStrict
        p.toneBoldNeutral = toneBoldNeutral
        p.toneShortDetailed = toneShortDetailed
        p.wordsToUse = wordsToUse
        p.wordsToAvoid = wordsToAvoid
        p.ctaStyle = ctaStyle
        p.favoritePhrases = favoritePhrases
        p.visualMood = selectedMood
        p.updatedAt = Date()
        
        try? modelContext.save()
    }
}

#Preview {
    BrandView()
        .environment(AppState())
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
