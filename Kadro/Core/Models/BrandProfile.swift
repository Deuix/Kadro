//
//  BrandProfile.swift
//  Kadro
//
//  Brand memory model — stores tone, style, and writing preferences
//

import Foundation
import SwiftData

// MARK: - User Type

enum UserType: String, Codable, CaseIterable, Identifiable {
    case creator = "Создатель контента"
    case expert = "Эксперт / Коуч"
    case smallBusiness = "Малый бизнес"
    case agency = "Агентство"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .creator: return "person.crop.circle"
        case .expert: return "lightbulb"
        case .smallBusiness: return "storefront"
        case .agency: return "person.3"
        }
    }
}

// MARK: - Tone Axis

enum ToneAxis: String, Codable, CaseIterable {
    case expertSimple = "Экспертность"       // expert ↔ simple
    case warmStrict = "Теплота"              // warm ↔ strict
    case boldNeutral = "Смелость"            // bold ↔ neutral
    case shortDetailed = "Детальность"       // short ↔ detailed
}

// MARK: - Visual Mood

enum VisualMood: String, Codable, CaseIterable, Identifiable {
    case minimal = "Минимализм"
    case bold = "Яркий"
    case editorial = "Редакторский"
    case soft = "Мягкий"
    case premium = "Премиум"
    
    var id: String { rawValue }
}

// MARK: - Brand Profile Model

@Model
final class BrandProfile {
    var id: UUID
    
    // Basics
    var brandName: String
    var niche: String
    var language: String
    var audience: String
    var userType: UserType?
    
    // Tone — stored as Float 0.0 to 1.0
    // 0.0 = expert / warm / bold / short
    // 1.0 = simple / strict / neutral / detailed
    var toneExpertSimple: Float
    var toneWarmStrict: Float
    var toneBoldNeutral: Float
    var toneShortDetailed: Float
    
    // Writing rules
    var wordsToUse: String
    var wordsToAvoid: String
    var ctaStyle: String
    var favoritePhrases: String
    
    // Visual style
    var visualMood: VisualMood
    var palettePreference: String
    var coverStyle: String
    
    // Best examples
    var bestExamples: String
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        brandName: String = "",
        niche: String = "",
        language: String = "Русский",
        audience: String = ""
    ) {
        self.id = UUID()
        self.brandName = brandName
        self.niche = niche
        self.language = language
        self.audience = audience
        
        self.toneExpertSimple = 0.3
        self.toneWarmStrict = 0.3
        self.toneBoldNeutral = 0.4
        self.toneShortDetailed = 0.5
        
        self.wordsToUse = ""
        self.wordsToAvoid = ""
        self.ctaStyle = ""
        self.favoritePhrases = ""
        
        self.visualMood = .minimal
        self.palettePreference = ""
        self.coverStyle = ""
        self.bestExamples = ""
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
