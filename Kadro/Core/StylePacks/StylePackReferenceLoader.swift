import Foundation
import ImageIO
import UniformTypeIdentifiers

struct StylePackReferenceAsset: Identifiable, Hashable {
    let id: String
    let filename: String
    let url: URL
    let mimeType: String
    let dataURL: String
}

enum StylePackReferenceLoader {
    static func referenceAssets(for packID: String, limit: Int = 4) throws -> [StylePackReferenceAsset] {
        try resourceURLs(for: packID, limit: limit).map { url in
            let originalMimeType = mimeType(forExtension: url.pathExtension)
            let optimizedPayload = try optimizedImagePayload(from: url, fallbackMimeType: originalMimeType)
            return StylePackReferenceAsset(
                id: url.lastPathComponent,
                filename: url.lastPathComponent,
                url: url,
                mimeType: optimizedPayload.mimeType,
                dataURL: "data:\(optimizedPayload.mimeType);base64,\(optimizedPayload.data.base64EncodedString())"
            )
        }
    }
    
    static func referenceCount(for packID: String) -> Int {
        (try? resourceURLs(for: packID, limit: nil).count) ?? 0
    }
    
    private static func resourceURLs(for packID: String, limit: Int?) throws -> [URL] {
        let prefix = packID.lowercased() + "_"
        let allowedExtensions = Set(["jpg", "jpeg", "png", "webp"])
        guard let resourceRoot = Bundle.main.resourceURL else { return [] }
        
        let enumerator = FileManager.default.enumerator(
            at: resourceRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        
        var matches: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            let ext = url.pathExtension.lowercased()
            guard allowedExtensions.contains(ext) else { continue }
            if url.lastPathComponent.lowercased().hasPrefix(prefix) {
                matches.append(url)
            }
        }
        
        matches.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        
        if let limit {
            return Array(matches.prefix(limit))
        }
        return matches
    }
    
    private static func mimeType(forExtension ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "webp": return "image/webp"
        default: return "application/octet-stream"
        }
    }
    
    private static func optimizedImagePayload(from url: URL, fallbackMimeType: String) throws -> (data: Data, mimeType: String) {
        let originalData = try Data(contentsOf: url)
        guard let source = CGImageSourceCreateWithData(originalData as CFData, nil) else {
            return (originalData, fallbackMimeType)
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1400,
        ]
        
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return (originalData, fallbackMimeType)
        }
        
        let hasAlpha = cgImageHasAlpha(image)
        let outputType = hasAlpha ? UTType.png.identifier : UTType.jpeg.identifier
        let outputMimeType = hasAlpha ? "image/png" : "image/jpeg"
        let destinationData = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(destinationData, outputType as CFString, 1, nil) else {
            return (originalData, fallbackMimeType)
        }
        
        let destinationOptions: [CFString: Any]? = hasAlpha
            ? nil
            : [kCGImageDestinationLossyCompressionQuality: 0.82]
        
        CGImageDestinationAddImage(destination, image, destinationOptions as CFDictionary?)
        guard CGImageDestinationFinalize(destination) else {
            return (originalData, fallbackMimeType)
        }
        
        return (destinationData as Data, outputMimeType)
    }
    
    private static func cgImageHasAlpha(_ image: CGImage) -> Bool {
        switch image.alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast:
            return true
        default:
            return false
        }
    }
}
