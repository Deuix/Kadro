//
//  KadroColors.swift
//  Kadro
//
//  Design System — Color tokens
//  Palette: Charcoal + Lime — fully adaptive for Light & Dark mode
//

import SwiftUI

extension Color {
    // MARK: - Primary (fixed, non-adaptive)

    /// Charcoal — primary text in light mode, bright surfaces in dark mode
    /// #171717
    static let kadroCharcoal = Color(red: 23/255, green: 23/255, blue: 23/255)

    /// Soft Ivory — main background in light mode
    /// #F5F1E8
    static let kadroIvory = Color(red: 245/255, green: 241/255, blue: 232/255)

    /// Muted Lime — accent, CTA, highlights (same in both modes)
    /// #C7D92C
    static let kadroLime = Color(red: 199/255, green: 217/255, blue: 44/255)

    // MARK: - Secondary (fixed)

    /// Warm Gray — secondary text
    /// #8E8A83
    static let kadroWarmGray = Color(red: 142/255, green: 138/255, blue: 131/255)

    /// Sand — secondary surface, borders (light mode)
    /// #DDD6C8
    static let kadroSand = Color(red: 221/255, green: 214/255, blue: 200/255)

    /// Soft White — card background in light mode
    /// #FFFDF8
    static let kadroSoftWhite = Color(red: 255/255, green: 253/255, blue: 248/255)

    // MARK: - Semantic (unchanged)

    /// Success green
    static let kadroSuccess = Color(red: 76/255, green: 175/255, blue: 80/255)

    /// Error / destructive red
    static let kadroError = Color(red: 211/255, green: 47/255, blue: 47/255)

    /// Warning amber
    static let kadroWarning = Color(red: 255/255, green: 167/255, blue: 38/255)

    // MARK: - Dark mode fixed values

    /// Pure black background — used in dark mode
    static let kadroDarkBackground = Color(red: 10/255, green: 10/255, blue: 10/255)

    /// Elevated surface in dark mode (cards, sheets)
    static let kadroDarkSurface = Color(red: 22/255, green: 22/255, blue: 22/255)

    /// Elevated surface 2 in dark mode (nested cards)
    static let kadroDarkSurface2 = Color(red: 32/255, green: 32/255, blue: 32/255)

    /// Separator / border in dark mode
    static let kadroDarkBorder = Color(red: 48/255, green: 48/255, blue: 48/255)

    /// Primary text in dark mode — near white
    static let kadroDarkPrimaryText = Color(red: 242/255, green: 242/255, blue: 242/255)

    /// Secondary text in dark mode — muted
    static let kadroDarkSecondaryText = Color(red: 140/255, green: 140/255, blue: 148/255)

    // MARK: - Adaptive semantic tokens
    // These switch automatically based on the current color scheme.

    /// Adaptive background: Ivory (light) / Near-black (dark)
    static var kadroAdaptiveBackground: Color {
        Color("KadroAdaptiveBackground")
    }

    /// Adaptive card surface: SoftWhite (light) / Dark surface (dark)
    static var kadroAdaptiveCard: Color {
        Color("KadroAdaptiveCard")
    }

    /// Adaptive primary text: Charcoal (light) / Near-white (dark)
    static var kadroAdaptivePrimaryText: Color {
        Color("KadroAdaptivePrimaryText")
    }

    /// Adaptive secondary text: WarmGray (light) / Muted gray (dark)
    static var kadroAdaptiveSecondaryText: Color {
        Color("KadroAdaptiveSecondaryText")
    }

    /// Adaptive border / separator: Sand (light) / DarkBorder (dark)
    static var kadroAdaptiveBorder: Color {
        Color("KadroAdaptiveBorder")
    }
}

// MARK: - Convenience ShapeStyle aliases

extension ShapeStyle where Self == Color {
    static var kadroBackground: Color    { .kadroAdaptiveBackground }
    static var kadroCardBackground: Color { .kadroAdaptiveCard }
    static var kadroAccent: Color         { .kadroLime }
    static var kadroPrimaryText: Color    { .kadroAdaptivePrimaryText }
    static var kadroSecondaryText: Color  { .kadroAdaptiveSecondaryText }
    static var kadroBorder: Color         { .kadroAdaptiveBorder }
}

// MARK: - Environment-based adaptive helpers (used in views)
// These give you the right colour without needing named asset catalogue entries.

extension Color {
    static func kadroBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? kadroDarkBackground : kadroIvory
    }

    static func kadroCard(for scheme: ColorScheme) -> Color {
        scheme == .dark ? kadroDarkSurface : kadroSoftWhite
    }

    static func kadroCard2(for scheme: ColorScheme) -> Color {
        scheme == .dark ? kadroDarkSurface2 : kadroSoftWhite
    }

    static func kadroPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? kadroDarkPrimaryText : kadroCharcoal
    }

    static func kadroSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? kadroDarkSecondaryText : kadroWarmGray
    }

    static func kadroBorderColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? kadroDarkBorder : kadroSand
    }
}
