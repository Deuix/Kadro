//
//  InputSource.swift
//  Kadro
//
//  Shared input source model used across AppState and Create flow
//

import Foundation

enum InputSource: String, CaseIterable, Identifiable {
    case topic = "Идея или тема"
    case voiceNote = "Голосовая заметка"
    case textOrLink = "Текст"
    
    var id: String { rawValue }
}
