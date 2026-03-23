import Foundation

final class KadroAIService {
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
    
    func generateContent(context: KadroGenerationContext) async throws -> KadroGenerationResponse {
        var request = URLRequest(url: SupabaseConfig.generateContentURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        
        let payload = KadroGenerationRequest(
            inputSource: context.inputSource,
            rawInput: context.rawInput,
            outputType: context.outputType.apiValue,
            tone: context.tone?.rawValue ?? "",
            goal: context.goal?.rawValue ?? "",
            platform: context.platform.rawValue,
            brandProfile: KadroBrandSnapshot(profile: context.brandProfile),
            includeCandidatePreview: false
        )
        request.httpBody = try encoder.encode(payload)
        
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        
        guard (200..<300).contains(statusCode) else {
            throw KadroAIServiceError.http(statusCode: statusCode, message: Self.extractMessage(from: data))
        }
        
        do {
            return try decoder.decode(KadroGenerationResponse.self, from: data)
        } catch {
            throw KadroAIServiceError.decoding(error)
        }
    }
    
    private static func extractMessage(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = object["error"] as? String ?? object["message"] as? String
        else {
            return "Не удалось обработать ответ сервера."
        }
        return message
    }
}

enum KadroAIServiceError: LocalizedError {
    case http(statusCode: Int, message: String)
    case decoding(Error)
    
    var errorDescription: String? {
        switch self {
        case .http(_, let message):
            return message
        case .decoding:
            return "Сервер вернул неожиданный формат ответа."
        }
    }
}
