import Foundation

struct KadroVoiceTranscriptionResponse: Decodable {
    let transcript: String
    let model: String
    let openrouterRequestId: String
    let fallbackUsed: Bool?
    let fallbackReason: String?
}

final class KadroVoiceTranscriptionService {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func transcribe(audioURL: URL, languageHint: String = "Русский") async throws -> KadroVoiceTranscriptionResponse {
        var request = URLRequest(url: SupabaseConfig.transcribeAudioURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try makeMultipartBody(audioURL: audioURL, languageHint: languageHint, boundary: boundary)
        
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        
        guard (200..<300).contains(statusCode) else {
            throw KadroVoiceTranscriptionError.http(statusCode: statusCode, message: Self.extractMessage(from: data))
        }
        
        do {
            return try decoder.decode(KadroVoiceTranscriptionResponse.self, from: data)
        } catch {
            throw KadroVoiceTranscriptionError.decoding(error)
        }
    }
    
    private func makeMultipartBody(audioURL: URL, languageHint: String, boundary: String) throws -> Data {
        let fileData = try Data(contentsOf: audioURL)
        let filename = audioURL.lastPathComponent
        let mimeType = mimeType(for: audioURL)
        
        var body = Data()
        body.appendMultipartField(named: "language_hint", value: languageHint, boundary: boundary)
        body.appendMultipartFile(
            named: "file",
            filename: filename,
            mimeType: mimeType,
            fileData: fileData,
            boundary: boundary
        )
        body.appendString("--\(boundary)--\r\n")
        return body
    }
    
    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "m4a": return "audio/m4a"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        case "aac": return "audio/aac"
        default: return "application/octet-stream"
        }
    }
    
    private static func extractMessage(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = object["error"] as? String ?? object["message"] as? String
        else {
            return "Не удалось расшифровать голосовую заметку."
        }
        return message
    }
}

enum KadroVoiceTranscriptionError: LocalizedError {
    case http(statusCode: Int, message: String)
    case decoding(Error)
    
    var errorDescription: String? {
        switch self {
        case .http(_, let message):
            return message
        case .decoding:
            return "Сервер вернул неожиданный формат транскрибации."
        }
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
    
    mutating func appendMultipartField(named name: String, value: String, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        appendString(value)
        appendString("\r\n")
    }
    
    mutating func appendMultipartFile(named name: String, filename: String, mimeType: String, fileData: Data, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        appendString("Content-Type: \(mimeType)\r\n\r\n")
        append(fileData)
        appendString("\r\n")
    }
}
