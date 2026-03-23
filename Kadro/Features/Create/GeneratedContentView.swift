import SwiftUI

struct GeneratedContentView: View {
    let result: GeneratedContentResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    
                    if !result.payload.hook.isEmpty {
                        textSection(title: "Хук", body: result.payload.hook)
                    }
                    
                    if !result.payload.mainText.isEmpty {
                        textSection(title: "Основной текст", body: result.payload.mainText)
                    }
                    
                    if !result.payload.cta.isEmpty {
                        textSection(title: "CTA", body: result.payload.cta)
                    }
                    
                    if !result.payload.shortVersion.isEmpty {
                        textSection(title: "Короткая версия", body: result.payload.shortVersion)
                    }
                    
                    if !result.payload.caption.isEmpty {
                        textSection(title: "Подпись", body: result.payload.caption)
                    }
                    
                    if !result.payload.hashtags.isEmpty {
                        tagSection
                    }
                    
                    if !result.payload.carousel.slides.isEmpty {
                        carouselSection
                    }
                    
                    if !result.payload.reels.scriptBeats.isEmpty || !result.payload.reels.onScreenText.isEmpty || !result.payload.reels.coverIdea.isEmpty {
                        reelsSection
                    }
                    
                    if !result.payload.stories.isEmpty {
                        storiesSection
                    }
                    
                    if !result.payload.variants.isEmpty {
                        variantsSection
                    }
                    
                    if !result.payload.suggestedNextActions.isEmpty {
                        nextActionsSection
                    }
                    
                    metadataSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.kadroIvory)
            .navigationTitle("Готово")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(.kadroLime)
                }
            }
        }
    }
    
    private var heroCard: some View {
        KadroCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    KadroStatusBadge(title: result.project.type.rawValue, color: .kadroLime)
                    Spacer()
                    Text("Сохранено в Контент")
                        .font(.kadroCaption)
                        .foregroundColor(.kadroWarmGray)
                }
                
                Text(result.payload.title)
                    .font(.kadroTitle2)
                    .foregroundColor(.kadroCharcoal)
                
                if !result.payload.summary.isEmpty {
                    Text(result.payload.summary)
                        .font(.kadroBody)
                        .foregroundColor(.kadroWarmGray)
                }
            }
        }
    }
    
    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Хэштеги")
            FlowLayout(spacing: 8) {
                ForEach(result.payload.hashtags, id: \.self) { hashtag in
                    KadroChip(title: hashtag, isSelected: false) {}
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    private var carouselSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Слайды карусели")
            VStack(spacing: 10) {
                ForEach(Array(result.payload.carousel.slides.enumerated()), id: \.offset) { index, slide in
                    KadroCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Слайд \(index + 1)")
                                .font(.kadroCaption)
                                .foregroundColor(.kadroWarmGray)
                            Text(slide.headline)
                                .font(.kadroTitle3)
                                .foregroundColor(.kadroCharcoal)
                            Text(slide.body)
                                .font(.kadroBody)
                                .foregroundColor(.kadroWarmGray)
                            if !slide.cta.isEmpty {
                                Text(slide.cta)
                                    .font(.kadroCallout)
                                    .foregroundColor(.kadroCharcoal)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var reelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Reels / TikTok")
            
            if !result.payload.reels.hook.isEmpty {
                textSection(title: "Reels hook", body: result.payload.reels.hook)
            }
            
            if !result.payload.reels.scriptBeats.isEmpty {
                bulletSection(title: "Сценарные биты", items: result.payload.reels.scriptBeats)
            }
            
            if !result.payload.reels.onScreenText.isEmpty {
                bulletSection(title: "Текст на экране", items: result.payload.reels.onScreenText)
            }
            
            if !result.payload.reels.coverIdea.isEmpty {
                textSection(title: "Идея обложки", body: result.payload.reels.coverIdea)
            }
        }
    }
    
    private var storiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Stories")
            VStack(spacing: 10) {
                ForEach(Array(result.payload.stories.enumerated()), id: \.offset) { index, frame in
                    KadroCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Сторис \(index + 1)")
                                .font(.kadroCaption)
                                .foregroundColor(.kadroWarmGray)
                            Text(frame.title)
                                .font(.kadroTitle3)
                                .foregroundColor(.kadroCharcoal)
                            Text(frame.body)
                                .font(.kadroBody)
                                .foregroundColor(.kadroWarmGray)
                            if !frame.stickerIdea.isEmpty {
                                Text("Стикер: \(frame.stickerIdea)")
                                    .font(.kadroCallout)
                                    .foregroundColor(.kadroCharcoal)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var variantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Варианты")
            VStack(spacing: 10) {
                ForEach(result.payload.variants) { variant in
                    KadroCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(variant.label)
                                .font(.kadroFootnote)
                                .foregroundColor(.kadroWarmGray)
                            Text(variant.text)
                                .font(.kadroBody)
                                .foregroundColor(.kadroCharcoal)
                        }
                    }
                }
            }
        }
    }
    
    private var nextActionsSection: some View {
        bulletSection(title: "Что можно сделать дальше", items: result.payload.suggestedNextActions)
    }
    
    private var metadataSection: some View {
        KadroCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI metadata")
                    .font(.kadroFootnote)
                    .foregroundColor(.kadroWarmGray)
                Text("Text: \(result.payload.metadata.textModel)")
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
                Text("Cheap ops: \(result.payload.metadata.cheapModel)")
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
                Text("Image: \(result.payload.metadata.imageModel)")
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
                Text("Candidate: \(result.payload.metadata.candidateModel)")
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
            }
        }
    }
    
    private func textSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: title)
            KadroCard {
                Text(body)
                    .font(.kadroBody)
                    .foregroundColor(.kadroCharcoal)
            }
        }
    }
    
    private func bulletSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: title)
            KadroCard {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.kadroLime)
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)
                            Text(item)
                                .font(.kadroBody)
                                .foregroundColor(.kadroCharcoal)
                        }
                    }
                }
            }
        }
    }
}
