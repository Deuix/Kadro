//
//  KadroComponents.swift
//  Kadro
//
//  Design System — Reusable UI Components
//

import SwiftUI

// MARK: - Primary Button

struct KadroPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isFullWidth: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kadroButton)
                .foregroundColor(.kadroCharcoal)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(Color.kadroLime)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Secondary Button

struct KadroSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kadroButton)
                .foregroundColor(.kadroCharcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(Color.kadroSoftWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.kadroSand, lineWidth: 1)
                )
        }
    }
}

// MARK: - Card

struct KadroCard<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.kadroSoftWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Action Card (tappable)

struct KadroActionCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.kadroLime)
                    .frame(width: 44, height: 44)
                    .background(Color.kadroCharcoal)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroCharcoal)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.kadroSand)
            }
            .padding(16)
            .background(Color.kadroSoftWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Quick Action Card (square, icon + label)

struct KadroQuickActionCard: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.kadroLime)
                
                Text(title)
                    .font(.kadroChip)
                    .foregroundColor(.kadroCharcoal)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.kadroSoftWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Chip

struct KadroChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kadroChip)
                .foregroundColor(isSelected ? .kadroCharcoal : .kadroWarmGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.kadroLime : Color.kadroSoftWhite)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.kadroSand, lineWidth: 1)
                )
        }
    }
}

// MARK: - Section Header

struct KadroSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "Все"
    
    var body: some View {
        HStack {
            Text(title)
                .font(.kadroTitle3)
                .foregroundColor(.kadroCharcoal)
            
            Spacer()
            
            if let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                }
            }
        }
    }
}

// MARK: - Status Badge

struct KadroStatusBadge: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.kadroCaption)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Empty State

struct KadroEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.kadroSand)
            
            Text(title)
                .font(.kadroTitle3)
                .foregroundColor(.kadroCharcoal)
            
            Text(subtitle)
                .font(.kadroCallout)
                .foregroundColor(.kadroWarmGray)
                .multilineTextAlignment(.center)
            
            if let buttonTitle, let action {
                KadroPrimaryButton(title: buttonTitle, action: action, isFullWidth: false)
                    .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

// MARK: - Previews

#Preview("Components") {
    ScrollView {
        VStack(spacing: 24) {
            KadroPrimaryButton(title: "Создать контент") {}
            
            KadroSecondaryButton(title: "Отмена") {}
            
            KadroCard {
                Text("Заголовок карточки")
                    .font(.kadroTitle3)
                Text("Описание")
                    .font(.kadroCallout)
                    .foregroundColor(.kadroWarmGray)
            }
            
            KadroActionCard(
                icon: "doc.text",
                title: "Instagram Пост",
                subtitle: "Текст с хуком и CTA"
            ) {}
            
            HStack(spacing: 12) {
                KadroQuickActionCard(icon: "text.quote", title: "Пост") {}
                KadroQuickActionCard(icon: "rectangle.split.3x1", title: "Карусель") {}
                KadroQuickActionCard(icon: "video", title: "Reels") {}
            }
            
            HStack(spacing: 8) {
                KadroChip(title: "Обучающий", isSelected: true) {}
                KadroChip(title: "Личный", isSelected: false) {}
                KadroChip(title: "Продающий", isSelected: false) {}
            }
            
            KadroSectionHeader(title: "Последние черновики") {}
            
            HStack(spacing: 8) {
                KadroStatusBadge(title: "Черновик", color: .kadroWarmGray)
                KadroStatusBadge(title: "Готово", color: .kadroSuccess)
                KadroStatusBadge(title: "Запланировано", color: .kadroLime)
            }
            
            KadroEmptyState(
                icon: "doc.text.magnifyingglass",
                title: "Пока пусто",
                subtitle: "Ваши черновики появятся здесь",
                buttonTitle: "Создать первый"
            ) {}
        }
        .padding()
    }
    .background(Color.kadroIvory)
}
