import Foundation

struct KadroBrandSnapshot: Codable {
    let brandName: String
    let niche: String
    let language: String
    let audience: String
    let userType: String
    let toneExpertSimple: Float
    let toneWarmStrict: Float
    let toneBoldNeutral: Float
    let toneShortDetailed: Float
    let wordsToUse: String
    let wordsToAvoid: String
    let ctaStyle: String
    let favoritePhrases: String
    let visualMood: String
    let selectedStylePackID: String
    let selectedStylePackName: String
    let stylePackPromptTemplate: String
    let stylePackNegativePrompt: String
    let stylePackReferenceFolder: String
    let palettePreference: String
    let coverStyle: String
    let bestExamples: String
    
    init(profile: BrandProfile?) {
        self.brandName = profile?.brandName ?? ""
        self.niche = profile?.niche ?? ""
        self.language = profile?.language ?? "Русский"
        self.audience = profile?.audience ?? ""
        self.userType = profile?.userType?.rawValue ?? ""
        self.toneExpertSimple = profile?.toneExpertSimple ?? 0.3
        self.toneWarmStrict = profile?.toneWarmStrict ?? 0.3
        self.toneBoldNeutral = profile?.toneBoldNeutral ?? 0.4
        self.toneShortDetailed = profile?.toneShortDetailed ?? 0.5
        self.wordsToUse = profile?.wordsToUse ?? ""
        self.wordsToAvoid = profile?.wordsToAvoid ?? ""
        self.ctaStyle = profile?.ctaStyle ?? ""
        self.favoritePhrases = profile?.favoritePhrases ?? ""
        let selectedStylePack = StylePackLibrary.pack(for: profile?.selectedStylePackID)
        self.visualMood = profile?.visualMood.rawValue ?? ""
        self.selectedStylePackID = profile?.selectedStylePackID ?? ""
        self.selectedStylePackName = profile?.selectedStylePackName ?? selectedStylePack?.displayName ?? ""
        self.stylePackPromptTemplate = selectedStylePack?.promptTemplate ?? ""
        self.stylePackNegativePrompt = selectedStylePack?.negativePrompt ?? ""
        self.stylePackReferenceFolder = selectedStylePack?.referenceFolder ?? ""
        self.palettePreference = profile?.palettePreference ?? ""
        self.coverStyle = profile?.coverStyle ?? ""
        self.bestExamples = profile?.bestExamples ?? ""
    }
}

struct KadroGenerationContext {
    let inputSource: String
    let rawInput: String
    let outputType: ContentType
    let tone: ContentTone?
    let goal: ContentGoal?
    let platform: ContentPlatform
    let brandProfile: BrandProfile?
}

struct KadroGenerationRequest: Encodable {
    let inputSource: String
    let rawInput: String
    let outputType: String
    let tone: String
    let goal: String
    let platform: String
    let brandProfile: KadroBrandSnapshot
    let includeCandidatePreview: Bool
}

struct KadroGenerationResponse: Decodable {
    let title: String
    let summary: String
    let hook: String
    let mainText: String
    let cta: String
    let shortVersion: String
    let caption: String
    let hashtags: [String]
    let carousel: KadroCarouselPayload
    let reels: KadroReelsPayload
    let stories: [KadroStoryFramePayload]
    let variants: [KadroVariantPayload]
    let suggestedNextActions: [String]
    let metadata: KadroGenerationMetadata
}

struct KadroCarouselPayload: Decodable {
    let coverTitle: String
    let slides: [KadroCarouselSlidePayload]
}

struct KadroCarouselSlidePayload: Decodable, Identifiable {
    let headline: String
    let body: String
    let cta: String
    
    var id: String { headline + body + cta }
}

struct KadroReelsPayload: Decodable {
    let hook: String
    let scriptBeats: [String]
    let onScreenText: [String]
    let caption: String
    let coverIdea: String
}

struct KadroStoryFramePayload: Decodable, Identifiable {
    let title: String
    let body: String
    let stickerIdea: String
    
    var id: String { title + body + stickerIdea }
}

struct KadroVariantPayload: Decodable, Identifiable {
    let label: String
    let text: String
    
    var id: String { label + text }
}

struct KadroGenerationMetadata: Decodable {
    let textModel: String
    let cheapModel: String
    let imageModel: String
    let candidateModel: String
    let openrouterRequestId: String
    let promptVersion: String
    let fallbackUsed: Bool?
    let fallbackReason: String?
}

struct GeneratedContentResult: Identifiable {
    let project: ContentProject
    let payload: KadroGenerationResponse
    
    var id: UUID { project.id }
}

extension ContentType {
    var apiValue: String {
        switch self {
        case .post: return "post"
        case .carousel: return "carousel"
        case .reels: return "reels"
        case .stories: return "stories"
        case .contentPack: return "content_pack"
        }
    }
    
    var defaultPlatform: ContentPlatform {
        switch self {
        case .reels, .contentPack:
            return .both
        case .post, .carousel, .stories:
            return .instagram
        }
    }
}

extension ContentProject {
    static func makeFromGeneration(
        context: KadroGenerationContext,
        payload: KadroGenerationResponse
    ) -> ContentProject {
        let project = ContentProject(
            title: payload.title,
            rawInput: context.rawInput,
            type: context.outputType,
            status: .ready,
            platform: context.platform
        )
        
        project.tone = context.tone
        project.goal = context.goal
        project.hook = payload.hook
        project.mainText = payload.mainText.isEmpty ? payload.summary : payload.mainText
        project.cta = payload.cta
        project.shortVersion = payload.shortVersion
        project.hashtags = payload.hashtags.joined(separator: " ")
        project.scriptBeats = payload.reels.scriptBeats.joined(separator: "\n• ").trimmingCharacters(in: .whitespacesAndNewlines)
        if let scriptBeats = project.scriptBeats, !scriptBeats.isEmpty {
            project.scriptBeats = "• " + scriptBeats
        }
        project.onScreenText = payload.reels.onScreenText.joined(separator: "\n")
        project.caption = payload.caption.isEmpty ? payload.reels.caption : payload.caption
        project.coverIdea = payload.reels.coverIdea.isEmpty ? payload.carousel.coverTitle : payload.reels.coverIdea
        
        if !payload.carousel.slides.isEmpty {
            project.slides = payload.carousel.slides.enumerated().map { index, slide in
                let model = CarouselSlide(
                    order: index + 1,
                    headline: slide.headline,
                    bodyText: slide.body,
                    ctaText: slide.cta,
                    layoutStyle: index == 0 ? .bigTitleTop : .centeredCopy,
                    visualStyle: .minimal
                )
                model.project = project
                return model
            }
        }
        
        if context.outputType == .stories, !payload.stories.isEmpty {
            let storyText = payload.stories.enumerated().map { index, frame in
                "Сторис \(index + 1): \(frame.title)\n\(frame.body)\nСтикер: \(frame.stickerIdea)"
            }.joined(separator: "\n\n")
            project.mainText = storyText
        }
        
        return project
    }
}
