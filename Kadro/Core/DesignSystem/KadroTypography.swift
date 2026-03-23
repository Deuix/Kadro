//
//  KadroTypography.swift
//  Kadro
//
//  Design System — Typography scale
//  Editorial, clean, bold hierarchy
//

import SwiftUI

extension Font {
    // MARK: - Display
    
    /// Large page titles — 34pt bold
    static let kadroLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    
    /// Section titles — 28pt bold
    static let kadroTitle = Font.system(size: 28, weight: .bold, design: .default)
    
    /// Card titles — 22pt semibold
    static let kadroTitle2 = Font.system(size: 22, weight: .semibold, design: .default)
    
    /// Subsection titles — 20pt semibold
    static let kadroTitle3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Body
    
    /// Primary body — 17pt regular
    static let kadroBody = Font.system(size: 17, weight: .regular, design: .default)
    
    /// Emphasized body — 17pt medium
    static let kadroBodyMedium = Font.system(size: 17, weight: .medium, design: .default)
    
    /// Secondary body — 15pt regular
    static let kadroCallout = Font.system(size: 15, weight: .regular, design: .default)
    
    /// Small text — 13pt regular
    static let kadroFootnote = Font.system(size: 13, weight: .regular, design: .default)
    
    /// Tiny labels — 11pt medium
    static let kadroCaption = Font.system(size: 11, weight: .medium, design: .default)
    
    // MARK: - Special
    
    /// Button text — 17pt semibold
    static let kadroButton = Font.system(size: 17, weight: .semibold, design: .default)
    
    /// Chip / tag text — 14pt medium
    static let kadroChip = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Tab bar label — 10pt medium
    static let kadroTabBar = Font.system(size: 10, weight: .medium, design: .default)
}
