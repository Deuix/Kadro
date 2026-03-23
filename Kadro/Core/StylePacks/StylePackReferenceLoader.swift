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
        let prefix = packID.lowercased() + "_"
        let allowedExtensions = Set(["jpg", "jpeg", "png", "webp"])
        
        let urls = (Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) ?? [])
            .filter { url in
                let ext = url.pathExtension.lowercased()
                return allowedExtensions.contains(ext) && url.lastPathComponent.lowercased().hasPrefix(prefix)
            }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .prefix(limit)
        
        return try urls.map { url in
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
        let prefix = packID.lowercased() + "_"
        let allowedExtensions = Set(["jpg", "jpeg", "png", "webp"])
        return (Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) ?? [])
            .filter { url in
                let ext = url.pathExtension.lowercased()
                return allowedExtensions.contains(ext) && url.lastPathComponent.lowercased().hasPrefix(prefix)
            }
            .count
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
