//
//  ContentProject.swift
//  Kadro
//
//  Core data model for content projects
//

import Foundation
import SwiftData

// MARK: - Enums

enum ContentType: String, Codable, CaseIterable, Identifiable {
    case post = "Пост"
    case carousel = "Карусель"
    case reels = "Reels/TikTok"
    case stories = "Stories"
    case contentPack = "Контент-пак"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .post: return "doc.text"
        case .carousel: return "rectangle.split.3x1"
        case .reels: return "video"
        case .stories: return "rectangle.stack"
        case .contentPack: return "square.stack.3d.up"
        }
    }
}

enum ContentStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "Черновик"
    case ready = "Готово"
    case scheduled = "Запланировано"
    case published = "Опубликовано"
    
    var id: String { rawValue }
}

enum ContentPlatform: String, Codable, CaseIterable, Identifiable {
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case both = "Все платформы"
    
    var id: String { rawValue }
}

enum ContentTone: String, Codable, CaseIterable, Identifiable {
    case educational = "Обучающий"
    case personal = "Личный"
    case sales = "Продающий"
    case authority = "Экспертный"
    case engagement = "Вовлекающий"
    
    var id: String { rawValue }
}

enum ContentGoal: String, Codable, CaseIterable, Identifiable {
    case awareness = "Узнаваемость"
    case trust = "Доверие"
    case sales = "Продажи"
    case engagement = "Вовлечение"
    case education = "Обучение"
    
    var id: String { rawValue }
}

// MARK: - Content Project Model

@Model
final class ContentProject {
    var id: UUID
    var title: String
    var rawInput: String
    var type: ContentType
    var status: ContentStatus
    var platform: ContentPlatform
    var tone: ContentTone?
    var goal: ContentGoal?
    var contentLanguage: String?
    var formatDetail: String?
    var preferredImageAspectRatio: String?
    var desiredSlideCount: Int?
    var selectedStylePackID: String?
    var selectedStylePackName: String?
    
    // Post content
    var hook: String?
    var mainText: String?
    var cta: String?
    var shortVersion: String?
    var hashtags: String?
    
    // Reels/TikTok content
    var scriptBeats: String?
    var onScreenText: String?
    var caption: String?
    var coverIdea: String?
    
    // Generated visuals
    @Attribute(.externalStorage) var generatedCoverImageData: Data?
    var generatedCoverImagePrompt: String?
    var generatedCoverImageModel: String?
    var generatedCoverImageStylePackID: String?
    var generatedCoverImageReferenceFilenames: String?
    var generatedCoverImageVisualKind: String?
    var generatedCoverImageUpdatedAt: Date?
    
    // Scheduling
    var scheduledDate: Date?
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var slides: [CarouselSlide]?
    
    init(
        title: String = "",
        rawInput: String = "",
        type: ContentType = .post,
        status: ContentStatus = .draft,
        platform: ContentPlatform = .instagram
    ) {
        self.id = UUID()
        self.title = title
        self.rawInput = rawInput
        self.type = type
        self.status = status
        self.platform = platform
        self.contentLanguage = nil
        self.formatDetail = nil
        self.preferredImageAspectRatio = nil
        self.desiredSlideCount = nil
        self.selectedStylePackID = nil
        self.selectedStylePackName = nil
        self.generatedCoverImageData = nil
        self.generatedCoverImagePrompt = nil
        self.generatedCoverImageModel = nil
        self.generatedCoverImageStylePackID = nil
        self.generatedCoverImageReferenceFilenames = nil
        self.generatedCoverImageVisualKind = nil
        self.generatedCoverImageUpdatedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.slides = []
    }
}

// MARK: - Carousel Slide Model

@Model
final class CarouselSlide {
    var id: UUID
    var order: Int
    var headline: String
    var bodyText: String
    var ctaText: String?
    var layoutStyle: SlideLayout
    var visualStyle: SlideVisualStyle
    @Attribute(.externalStorage) var generatedImageData: Data?
    var generatedImagePrompt: String?
    var generatedImageModel: String?
    var generatedImageStylePackID: String?
    var generatedImageReferenceFilenames: String?
    var generatedImageVisualKind: String?
    var generatedImageUpdatedAt: Date?
    
    @Relationship(inverse: \ContentProject.slides)
    var project: ContentProject?
    
    init(
        order: Int = 0,
        headline: String = "",
        bodyText: String = "",
        ctaText: String? = nil,
        layoutStyle: SlideLayout = .bigTitleTop,
        visualStyle: SlideVisualStyle = .minimal
    ) {
        self.id = UUID()
        self.order = order
        self.headline = headline
        self.bodyText = bodyText
        self.ctaText = ctaText
        self.layoutStyle = layoutStyle
        self.visualStyle = visualStyle
        self.generatedImageData = nil
        self.generatedImagePrompt = nil
        self.generatedImageModel = nil
        self.generatedImageStylePackID = nil
        self.generatedImageReferenceFilenames = nil
        self.generatedImageVisualKind = nil
        self.generatedImageUpdatedAt = nil
    }
}

// MARK: - Slide Enums

enum SlideLayout: String, Codable, CaseIterable, Identifiable {
    case bigTitleTop = "Крупный заголовок"
    case centeredCopy = "По центру"
    case splitSections = "Разделённый"
    case numberFocused = "Числовой"
    case ctaFocused = "CTA"
    
    var id: String { rawValue }
}

enum SlideVisualStyle: String, Codable, CaseIterable, Identifiable {
    case minimal = "Минимализм"
    case bold = "Жирный"
    case editorial = "Редакторский"
    case soft = "Мягкий"
    case premium = "Премиум"
    
    var id: String { rawValue }
}
