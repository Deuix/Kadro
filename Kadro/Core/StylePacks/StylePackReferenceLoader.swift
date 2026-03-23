import Foundation

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
            let data = try Data(contentsOf: url)
            let mimeType = mimeType(forExtension: url.pathExtension)
            return StylePackReferenceAsset(
                id: url.lastPathComponent,
                filename: url.lastPathComponent,
                url: url,
                mimeType: mimeType,
                dataURL: "data:\(mimeType);base64,\(data.base64EncodedString())"
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
}
