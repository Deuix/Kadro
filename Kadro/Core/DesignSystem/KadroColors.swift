//
//  KadroColors.swift
//  Kadro
//
//  Design System — Color tokens
//  Palette: Charcoal + Lime
//

import SwiftUI

extension Color {
    // MARK: - Primary
    
    /// Charcoal — primary text, dark surfaces
    /// #171717
    static let kadroCharcoal = Color(red: 23/255, green: 23/255, blue: 23/255)
    
    /// Soft Ivory — main background
    /// #F5F1E8
    static let kadroIvory = Color(red: 245/255, green: 241/255, blue: 232/255)
    
    /// Muted Lime — accent, CTA, highlights
    /// #C7D92C
    static let kadroLime = Color(red: 199/255, green: 217/255, blue: 44/255)
    
    // MARK: - Secondary
    
    /// Warm Gray — secondary text
    /// #8E8A83
    static let kadroWarmGray = Color(red: 142/255, green: 138/255, blue: 131/255)
    
    /// Sand — secondary surface, borders
    /// #DDD6C8
    static let kadroSand = Color(red: 221/255, green: 214/255, blue: 200/255)
    
    /// Soft White — card background
    /// #FFFDF8
    static let kadroSoftWhite = Color(red: 255/255, green: 253/255, blue: 248/255)
    
    // MARK: - Semantic
    
    /// Success green
    static let kadroSuccess = Color(red: 76/255, green: 175/255, blue: 80/255)
    
    /// Error / destructive red
    static let kadroError = Color(red: 211/255, green: 47/255, blue: 47/255)
    
    /// Warning amber
    static let kadroWarning = Color(red: 255/255, green: 167/255, blue: 38/255)
}

// MARK: - Convenience

extension ShapeStyle where Self == Color {
    static var kadroBackground: Color { .kadroIvory }
    static var kadroCardBackground: Color { .kadroSoftWhite }
    static var kadroAccent: Color { .kadroLime }
    static var kadroPrimaryText: Color { .kadroCharcoal }
    static var kadroSecondaryText: Color { .kadroWarmGray }
    static var kadroBorder: Color { .kadroSand }
}
