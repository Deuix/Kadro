import Foundation

enum StylePackLibrary {
    static let packs: [StylePack] = loadPacks()
    
    static func pack(for id: String?) -> StylePack? {
        guard let id, !id.isEmpty else { return nil }
        return packs.first(where: { $0.id == id })
    }
    
    private static func loadPacks() -> [StylePack] {
        let decoder = JSONDecoder()
        
        if let url = Bundle.main.url(forResource: "style_packs", withExtension: "json", subdirectory: "Resources/StylePacks"),
           let data = try? Data(contentsOf: url),
           let decoded = try? decoder.decode([StylePack].self, from: data),
           !decoded.isEmpty {
            return decoded
        }
        
        return fallbackPacks
    }
    
    private static let fallbackPacks: [StylePack] = [
        StylePack(
            id: "minimalistic",
            name: "Minimalistic",
            russianName: "Минималистичный",
            shortDescription: "Чистая сетка, много воздуха, строгая иерархия и спокойный premium look.",
            moodDescription: "calm, editorial, precise",
            defaultVisualMoodKey: "minimal",
            promptTemplate: "Use generous whitespace, restrained palette, clean typography, one clear focal block, and disciplined layout rhythm.",
            negativePrompt: "No clutter, no neon gradients, no generic AI glow, no sticker overload.",
            referenceFolder: "Resources/StylePacks/minimalistic/references",
            recommendedUse: ["carousel", "stories", "content_pack"],
            accentPalette: ["ivory", "charcoal", "lime"],
            referenceNotes: ["Keep text short on covers", "Prefer one dominant block per slide"]
        ),
        StylePack(
            id: "elegant",
            name: "Elegant",
            russianName: "Элегантный",
            shortDescription: "Editorial luxury feel с refined typography, мягким ритмом и restrained color palette.",
            moodDescription: "luxury, refined, composed",
            defaultVisualMoodKey: "premium",
            promptTemplate: "Use refined typography, soft luxury spacing, premium restraint, subtle contrast, and polished editorial balance.",
            negativePrompt: "No cheap glam, no loud gradients, no aggressive effects, no noisy textures.",
            referenceFolder: "Resources/StylePacks/elegant/references",
            recommendedUse: ["carousel", "cover", "brand_posts"],
            accentPalette: ["bone", "espresso", "muted gold"],
            referenceNotes: ["Focus on hierarchy and calm contrast", "Avoid overdesigned decorative elements"]
        ),
        StylePack(
            id: "dark",
            name: "Dark",
            russianName: "Тёмный",
            shortDescription: "Глубокие тёмные поверхности, высокий контраст и cinematic premium mood.",
            moodDescription: "dark, cinematic, sharp",
            defaultVisualMoodKey: "dark",
            promptTemplate: "Use dark premium surfaces, high-contrast typography, subtle glow or grain, and a strong focal center.",
            negativePrompt: "No gamer neon overload, no chaotic shadows, no low-legibility compositions.",
            referenceFolder: "Resources/StylePacks/dark/references",
            recommendedUse: ["reels_cover", "carousel", "launch_assets"],
            accentPalette: ["black", "graphite", "acid lime"],
            referenceNotes: ["Protect readability first", "Use glow very sparingly"]
        )
    ]
}
