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
    private let stylePacks = StylePackLibrary.packs
    
    @State private var brandName: String = ""
    @State private var niche: String = ""
    @State private var audience: String = ""
    @State private var selectedUserType: UserType?
    
    @State private var toneExpertSimple: Float = 0.3
    @State private var toneWarmStrict: Float = 0.3
    @State private var toneBoldNeutral: Float = 0.4
    @State private var toneShortDetailed: Float = 0.5
    
    @State private var wordsToUse: String = ""
    @State private var wordsToAvoid: String = ""
    @State private var ctaStyle: String = ""
    @State private var favoritePhrases: String = ""
    
    @State private var selectedMood: VisualMood = .minimal
    @State private var selectedStylePackID: String = ""
    @State private var palettePreference: String = ""
    @State private var coverStyle: String = ""
    @State private var bestExamples: String = ""
    
    @State private var hasLoaded = false
    
    private var selectedStylePack: StylePack? {
        StylePackLibrary.pack(for: selectedStylePackID)
    }
    
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
            .navigationTitle(L10n.Brand.navTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(L10n.Brand.save) {
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
    
    private var basicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            KadroSectionHeader(title: L10n.Brand.sectionBasics)

            KadroCard {
                VStack(spacing: 14) {
                    brandTextField(title: L10n.Brand.brandName, text: $brandName, placeholder: L10n.Brand.brandNamePlaceholder)
                    brandTextField(title: L10n.Brand.niche, text: $niche, placeholder: L10n.Brand.nichePlaceholder)
                    brandTextField(title: L10n.Brand.audience, text: $audience, placeholder: L10n.Brand.audiencePlaceholder)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.Brand.profileType)
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
                                
                                Text(type.displayName)
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
    
    private var toneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            KadroSectionHeader(title: L10n.Brand.toneSection)

            KadroCard {
                VStack(spacing: 18) {
                    toneSlider(title: L10n.Brand.toneExpert, leftLabel: L10n.Brand.toneExpertLeft, rightLabel: L10n.Brand.toneExpertRight, value: $toneExpertSimple)
                    toneSlider(title: L10n.Brand.toneWarmth, leftLabel: L10n.Brand.toneWarmthLeft, rightLabel: L10n.Brand.toneWarmthRight, value: $toneWarmStrict)
                    toneSlider(title: L10n.Brand.toneBoldness, leftLabel: L10n.Brand.toneBoldnessLeft, rightLabel: L10n.Brand.toneBoldnessRight, value: $toneBoldNeutral)
                    toneSlider(title: L10n.Brand.toneDetail, leftLabel: L10n.Brand.toneDetailLeft, rightLabel: L10n.Brand.toneDetailRight, value: $toneShortDetailed)
                }
            }
        }
    }
    
    private var writingRulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            KadroSectionHeader(title: L10n.Brand.writingRules)

            KadroCard {
                VStack(spacing: 14) {
                    brandTextField(title: L10n.Brand.wordsToUse, text: $wordsToUse, placeholder: L10n.Brand.wordsToUsePlaceholder)
                    brandTextField(title: L10n.Brand.wordsToAvoid, text: $wordsToAvoid, placeholder: L10n.Brand.wordsToAvoidPlaceholder)
                    brandTextField(title: L10n.Brand.ctaStyle, text: $ctaStyle, placeholder: L10n.Brand.ctaStylePlaceholder)
                    brandTextField(title: L10n.Brand.favoritePhrases, text: $favoritePhrases, placeholder: L10n.Brand.favoritePhrasesPlaceholder)
                }
            }
        }
    }
    
    private var visualStyleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            KadroSectionHeader(title: L10n.Brand.sectionVisualStyle)
            
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
                                
                                Text(mood.displayName)
                                    .font(.kadroChip)
                                    .foregroundColor(selectedMood == mood ? .kadroCharcoal : .kadroWarmGray)
                            }
                        }
                    }
                }
            }
            
            stylePackSection
            advancedVisualSection
        }
    }
    
    private var stylePackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Brand.stylePacks)
                .font(.kadroTitle3)
                .foregroundColor(.kadroCharcoal)
            
            Text(L10n.Brand.stylePacksHint)
                .font(.kadroCallout)
                .foregroundColor(.kadroWarmGray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stylePacks, id: \.id) { pack in
                        Button {
                            selectedStylePackID = pack.id
                            if let mood = pack.visualMood {
                                selectedMood = mood
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(stylePackColor(for: pack))
                                    .frame(width: 180, height: 96)
                                    .overlay(alignment: .bottomLeading) {
                                        Text(pack.displayName)
                                            .font(.kadroBodyMedium)
                                            .foregroundColor(pack.id == "dark" ? .white : .kadroCharcoal)
                                            .padding(12)
                                    }
                                
                                Text(pack.shortDescription)
                                    .font(.kadroFootnote)
                                    .foregroundColor(.kadroWarmGray)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(3)
                                
                                Text(pack.referenceFolder)
                                    .font(.kadroCaption)
                                    .foregroundColor(.kadroWarmGray)
                                    .lineLimit(2)
                            }
                            .padding(12)
                            .frame(width: 220, alignment: .leading)
                            .background(Color.kadroSoftWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(selectedStylePackID == pack.id ? Color.kadroLime : Color.kadroSand.opacity(0.6), lineWidth: selectedStylePackID == pack.id ? 2 : 1)
                            )
                        }
                    }
                }
            }
            
            if let selectedStylePack {
                KadroCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.Brand.selectedStylePack(selectedStylePack.displayName))
                            .font(.kadroBodyMedium)
                            .foregroundColor(.kadroCharcoal)
                        Text(selectedStylePack.moodDescription)
                            .font(.kadroCallout)
                            .foregroundColor(.kadroWarmGray)
                        Text("Prompt template")
                            .font(.kadroCaption)
                            .foregroundColor(.kadroWarmGray)
                        Text(selectedStylePack.promptTemplate)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroCharcoal)
                        Text("Negative")
                            .font(.kadroCaption)
                            .foregroundColor(.kadroWarmGray)
                        Text(selectedStylePack.negativePrompt)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroCharcoal)
                    }
                }
            }
        }
    }
    
    private var advancedVisualSection: some View {
        KadroCard {
            VStack(spacing: 14) {
                brandTextField(title: L10n.Brand.palette, text: $palettePreference, placeholder: L10n.Brand.palettePlaceholder)
                brandTextField(title: L10n.Brand.coverStyle, text: $coverStyle, placeholder: L10n.Brand.coverStylePlaceholder)
                multilineField(title: L10n.Brand.references, text: $bestExamples, placeholder: L10n.Brand.referencesPlaceholder)
            }
        }
    }
    
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
    
    private func multilineField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.kadroFootnote)
                .foregroundColor(.kadroWarmGray)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .font(.kadroBody)
                    .foregroundColor(.kadroCharcoal)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color.kadroIvory)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray.opacity(0.7))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
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
    
    private func moodColor(for mood: VisualMood) -> Color {
        switch mood {
        case .minimal: return .kadroSoftWhite
        case .bold: return .kadroCharcoal
        case .editorial: return .kadroSand
        case .soft: return .kadroIvory
        case .premium: return .kadroCharcoal.opacity(0.8)
        }
    }
    
    private func stylePackColor(for pack: StylePack) -> Color {
        switch pack.id {
        case "minimalistic": return .kadroSoftWhite
        case "elegant": return Color(red: 234/255, green: 226/255, blue: 210/255)
        case "dark": return .kadroCharcoal
        case "modern": return Color(red: 223/255, green: 230/255, blue: 236/255)
        case "texty": return Color(red: 247/255, green: 244/255, blue: 237/255)
        default: return .kadroSand
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
        selectedStylePackID = p.selectedStylePackID
        palettePreference = p.palettePreference
        coverStyle = p.coverStyle
        bestExamples = p.bestExamples
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
        p.selectedStylePackID = selectedStylePackID
        p.selectedStylePackName = selectedStylePack?.displayName ?? ""
        p.palettePreference = palettePreference
        p.coverStyle = coverStyle
        p.bestExamples = bestExamples
        p.updatedAt = Date()
        
        try? modelContext.save()
    }
}

#Preview {
    BrandView()
        .environment(AppState())
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
