import Foundation

struct StylePack: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let russianName: String
    let shortDescription: String
    let moodDescription: String
    let defaultVisualMoodKey: String
    let promptTemplate: String
    let negativePrompt: String
    let referenceFolder: String
    let recommendedUse: [String]
    let accentPalette: [String]
    let referenceNotes: [String]
    
    var displayName: String {
        russianName.isEmpty ? name : russianName
    }
    
    var visualMood: VisualMood? {
        VisualMood(stylePackKey: defaultVisualMoodKey)
    }
}

extension VisualMood {
    init?(stylePackKey: String) {
        switch stylePackKey {
        case "minimal": self = .minimal
        case "bold": self = .bold
        case "editorial": self = .editorial
        case "soft": self = .soft
        case "premium", "dark": self = .premium
        default: return nil
        }
    }
}
