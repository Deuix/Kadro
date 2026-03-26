import Foundation

enum KadroStyleVisualTarget: Hashable {
    case cover
    case slide(UUID)
}

struct KadroStyleImageRequest: Encodable {
    let projectTitle: String
    let rawInput: String
    let outputType: String
    let visualKind: String
    let aspectRatio: String
    let primaryText: String
    let secondaryText: String
    let stylePackID: String
    let stylePackName: String
    let stylePackPromptTemplate: String
    let stylePackNegativePrompt: String
    let stylePackReferenceFolder: String
    let referenceImages: [KadroStyleReferenceImagePayload]
    let baseImageDataURL: String?
    let promptOverride: String?
}

struct KadroStyleReferenceImagePayload: Encodable {
    let filename: String
    let dataURL: String
}

struct KadroGeneratedStyleImageResponse: Decodable, Identifiable {
    let imageDataURL: String
    let model: String
    let openrouterRequestID: String
    let promptVersion: String
    let stylePackID: String
    let referenceCount: Int
    let referenceFilenames: [String]
    let visualKind: String
    let promptUsed: String
    
    var id: String { openrouterRequestID + stylePackID + visualKind }
    
    private enum CodingKeys: String, CodingKey {
        case imageDataURL = "image_data_url"
        case model = "model"
        case openrouterRequestID = "openrouter_request_id"
        case promptVersion = "prompt_version"
        case stylePackID = "style_pack_id"
        case referenceCount = "reference_count"
        case referenceFilenames = "reference_filenames"
        case visualKind = "visual_kind"
        case promptUsed = "prompt_used"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.imageDataURL = try container.decode(String.self, forKey: .imageDataURL)
        self.model = try container.decodeIfPresent(String.self, forKey: .model) ?? ""
        self.openrouterRequestID = try container.decodeIfPresent(String.self, forKey: .openrouterRequestID) ?? UUID().uuidString
        self.promptVersion = try container.decodeIfPresent(String.self, forKey: .promptVersion) ?? ""
        self.stylePackID = try container.decodeIfPresent(String.self, forKey: .stylePackID) ?? ""
        self.referenceCount = try container.decodeIfPresent(Int.self, forKey: .referenceCount) ?? 0
        self.referenceFilenames = try container.decodeIfPresent([String].self, forKey: .referenceFilenames) ?? []
        self.visualKind = try container.decodeIfPresent(String.self, forKey: .visualKind) ?? "cover"
        self.promptUsed = try container.decodeIfPresent(String.self, forKey: .promptUsed) ?? ""
    }
}

final class KadroStyleImageService {
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    func generateCoverVisual(
        project: ContentProject,
        brandProfile: BrandProfile?,
        promptOverride: String? = nil
    ) async throws -> KadroGeneratedStyleImageResponse {
        try await generateVisual(project: project, slide: nil, brandProfile: brandProfile, promptOverride: promptOverride)
    }
    
    func generateSlideVisual(
        project: ContentProject,
        slide: CarouselSlide,
        brandProfile: BrandProfile?,
        promptOverride: String? = nil
    ) async throws -> KadroGeneratedStyleImageResponse {
        try await generateVisual(project: project, slide: slide, brandProfile: brandProfile, promptOverride: promptOverride)
    }
    
    func imageData(from dataURL: String) -> Data? {
        guard let commaIndex = dataURL.firstIndex(of: ",") else { return nil }
        let base64 = String(dataURL[dataURL.index(after: commaIndex)...])
        return Data(base64Encoded: base64)
    }
    
    func dataURL(from imageData: Data, mimeType: String = "image/png") -> String {
        "data:\(mimeType);base64,\(imageData.base64EncodedString())"
    }
    
    private func generateVisual(
        project: ContentProject,
        slide: CarouselSlide?,
        brandProfile: BrandProfile?,
        promptOverride: String?
    ) async throws -> KadroGeneratedStyleImageResponse {
        guard let stylePack = resolvedStylePack(project: project, brandProfile: brandProfile) else {
            throw KadroStyleImageServiceError.missingStylePack
        }
        
        let baseImageDataURL = resolvedBaseImageDataURL(project: project, slide: slide)
        let referenceLimit = baseImageDataURL == nil ? 2 : 1
        let references = try StylePackReferenceLoader.referenceAssets(for: stylePack.id, limit: referenceLimit)
        guard !references.isEmpty else {
            throw KadroStyleImageServiceError.missingReferences(stylePack.displayName)
        }
        
        let primaryText = resolvedPrimaryText(for: project, slide: slide)
        let secondaryText = resolvedSecondaryText(for: project, slide: slide)
        let visualKind = slide == nil ? "cover" : slideVisualKind(for: slide!)
        
        let requestBody = KadroStyleImageRequest(
            projectTitle: project.title,
            rawInput: project.rawInput,
            outputType: project.type.apiValue,
            visualKind: visualKind,
            aspectRatio: aspectRatio(for: project),
            primaryText: primaryText,
            secondaryText: secondaryText,
            stylePackID: stylePack.id,
            stylePackName: stylePack.displayName,
            stylePackPromptTemplate: stylePack.promptTemplate,
            stylePackNegativePrompt: stylePack.negativePrompt,
            stylePackReferenceFolder: stylePack.referenceFolder,
            referenceImages: references.map { KadroStyleReferenceImagePayload(filename: $0.filename, dataURL: $0.dataURL) },
            baseImageDataURL: baseImageDataURL,
            promptOverride: promptOverride?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        var request = URLRequest(url: URL(string: SupabaseConfig.projectURLString + "/functions/v1/generate-style-visual")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        
        guard (200..<300).contains(statusCode) else {
            throw KadroStyleImageServiceError.http(statusCode: statusCode, message: Self.extractMessage(from: data))
        }
        
        do {
            return try decoder.decode(KadroGeneratedStyleImageResponse.self, from: data)
        } catch {
            throw KadroStyleImageServiceError.decoding(error)
        }
    }
    
    private func resolvedStylePack(project: ContentProject, brandProfile: BrandProfile?) -> StylePack? {
        if let selected = StylePackLibrary.pack(for: project.selectedStylePackID) {
            return selected
        }
        if let selected = StylePackLibrary.pack(for: brandProfile?.selectedStylePackID) {
            return selected
        }
        return StylePackLibrary.packs.first
    }
    
    private func resolvedPrimaryText(for project: ContentProject, slide: CarouselSlide?) -> String {
        if let slide, !slide.headline.isEmpty {
            return slide.headline
        }
        if let hook = project.hook, !hook.isEmpty {
            return hook
        }
        if !project.title.isEmpty {
            return project.title
        }
        return project.rawInput
    }
    
    private func resolvedSecondaryText(for project: ContentProject, slide: CarouselSlide?) -> String {
        if let slide {
            if !slide.bodyText.isEmpty {
                return slide.bodyText
            }
            if let cta = slide.ctaText, !cta.isEmpty {
                return cta
            }
        }
        return project.cta ?? project.caption ?? ""
    }
    
    private func slideVisualKind(for slide: CarouselSlide) -> String {
        if let cta = slide.ctaText, !cta.isEmpty {
            return "cta_slide"
        }
        if slide.bodyText.count > 120 {
            return "text_heavy_slide"
        }
        return "quote_card"
    }
    
    private func resolvedBaseImageDataURL(
        project: ContentProject,
        slide: CarouselSlide?
    ) -> String? {
        if let slide {
            if let existingSlideImage = slide.generatedImageData {
                return dataURL(from: existingSlideImage)
            }
            if let previousSlide = previousGeneratedSlideImageData(in: project, before: slide.order) {
                return dataURL(from: previousSlide)
            }
            if let cover = project.generatedCoverImageData {
                return dataURL(from: cover)
            }
            return nil
        }
        
        if let cover = project.generatedCoverImageData {
            return dataURL(from: cover)
        }
        
        return nil
    }
    
    private func previousGeneratedSlideImageData(in project: ContentProject, before order: Int) -> Data? {
        let candidateSlides = (project.slides ?? [])
            .filter { $0.order < order }
            .sorted { $0.order > $1.order }
        
        for candidate in candidateSlides {
            if let imageData = candidate.generatedImageData {
                return imageData
            }
        }
        
        return nil
    }
    
    private func aspectRatio(for project: ContentProject) -> String {
        if let preferred = project.preferredImageAspectRatio?.trimmingCharacters(in: .whitespacesAndNewlines), !preferred.isEmpty {
            return preferred
        }
        
        if let formatDetail = project.formatDetail?.trimmingCharacters(in: .whitespacesAndNewlines), !formatDetail.isEmpty {
            switch formatDetail {
            case "instagram_post_square", "instagram_carousel_square":
                return "1:1"
            case "instagram_post_portrait", "instagram_carousel", "instagram_carousel_portrait":
                return "4:5"
            case "instagram_story":
                return "9:16"
            default:
                break
            }
        }
        
        switch project.type {
        case .reels, .stories:
            return "9:16"
        case .post, .carousel, .contentPack:
            return "4:5"
        }
    }
    
    private static func extractMessage(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = object["error"] as? String ?? object["message"] as? String
        else {
            return "Не удалось сгенерировать визуал."
        }
        return message
    }
}

enum KadroStyleImageServiceError: LocalizedError {
    case missingStylePack
    case missingReferences(String)
    case http(statusCode: Int, message: String)
    case decoding(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingStylePack:
            return "Сначала выберите style pack в разделе Create."
        case .missingReferences(let styleName):
            return "Для style pack \(styleName) не найдены reference images в bundle."
        case .http(_, let message):
            return message
        case .decoding:
            return "Сервер вернул неожиданный формат image generation ответа."
        }
    }
}
