import Foundation

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
    let promptUsed: String
    
    var id: String { openrouterRequestID + stylePackID }
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
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func generateCoverVisual(project: ContentProject, brandProfile: BrandProfile?) async throws -> KadroGeneratedStyleImageResponse {
        guard let stylePack = resolvedStylePack(from: brandProfile) else {
            throw KadroStyleImageServiceError.missingStylePack
        }
        
        let references = try StylePackReferenceLoader.referenceAssets(for: stylePack.id)
        guard !references.isEmpty else {
            throw KadroStyleImageServiceError.missingReferences(stylePack.displayName)
        }
        
        let primaryText = resolvedPrimaryText(for: project)
        let secondaryText = project.cta ?? project.caption ?? ""
        
        let requestBody = KadroStyleImageRequest(
            projectTitle: project.title,
            rawInput: project.rawInput,
            outputType: project.type.apiValue,
            visualKind: "cover",
            aspectRatio: aspectRatio(for: project.type),
            primaryText: primaryText,
            secondaryText: secondaryText,
            stylePackID: stylePack.id,
            stylePackName: stylePack.displayName,
            stylePackPromptTemplate: stylePack.promptTemplate,
            stylePackNegativePrompt: stylePack.negativePrompt,
            stylePackReferenceFolder: stylePack.referenceFolder,
            referenceImages: references.map { KadroStyleReferenceImagePayload(filename: $0.filename, dataURL: $0.dataURL) }
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
    
    private func resolvedStylePack(from profile: BrandProfile?) -> StylePack? {
        if let selected = StylePackLibrary.pack(for: profile?.selectedStylePackID) {
            return selected
        }
        return StylePackLibrary.packs.first
    }
    
    private func resolvedPrimaryText(for project: ContentProject) -> String {
        if let hook = project.hook, !hook.isEmpty {
            return hook
        }
        if !project.title.isEmpty {
            return project.title
        }
        return project.rawInput
    }
    
    private func aspectRatio(for type: ContentType) -> String {
        switch type {
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
            return "Сначала выберите style pack в разделе Brand."
        case .missingReferences(let styleName):
            return "Для style pack \(styleName) не найдены reference images в bundle."
        case .http(_, let message):
            return message
        case .decoding:
            return "Сервер вернул неожиданный формат image generation ответа."
        }
    }
}
