//
//  SettingsView.swift
//  Kadro
//
//  Settings screen — account, subscription, notifications, export, support
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    // Account section
                    SettingsSection(title: "Аккаунт") {
                        SettingsRow(icon: "person.circle", title: "Профиль", color: .kadroCharcoal) {}
                        SettingsDivider()
                        SettingsRow(icon: "envelope", title: "Email", subtitle: "Не привязан", color: .kadroCharcoal) {}
                    }

                    // Subscription section
                    SettingsSection(title: "Подписка") {
                        SettingsRow(icon: "star.circle.fill", title: "Kadro Pro", subtitle: "Бесплатный план", color: .kadroLime) {}
                        SettingsDivider()
                        SettingsRow(icon: "arrow.clockwise.circle", title: "Восстановить покупки", color: .kadroCharcoal) {}
                    }

                    // App section
                    SettingsSection(title: "Приложение") {
                        SettingsLanguageRow()
                        SettingsDivider()
                        SettingsToggleRow(icon: "bell", title: "Уведомления", color: .kadroCharcoal)
                        SettingsDivider()
                        SettingsRow(icon: "square.and.arrow.up", title: "Экспорт данных", color: .kadroCharcoal) {}
                    }

                    // Connections section
                    SettingsSection(title: "Подключения") {
                        SettingsRow(
                            icon: "link.circle",
                            title: "Подключённые платформы",
                            subtitle: "Instagram, TikTok",
                            color: .kadroCharcoal
                        ) {}
                    }

                    // Support section
                    SettingsSection(title: "Поддержка") {
                        SettingsRow(icon: "questionmark.circle", title: "Помощь и FAQ", color: .kadroCharcoal) {}
                        SettingsDivider()
                        SettingsRow(icon: "envelope.badge", title: "Написать нам", color: .kadroCharcoal) {}
                        SettingsDivider()
                        SettingsRow(icon: "star", title: "Оценить приложение", color: .kadroCharcoal) {}
                    }

                    // App info
                    SettingsSection(title: "О приложении") {
                        SettingsRow(icon: "info.circle", title: "Версия", subtitle: "1.0.0 (Build 1)", color: .kadroWarmGray) {}
                        SettingsDivider()
                        SettingsRow(icon: "doc.text", title: "Условия использования", color: .kadroCharcoal) {}
                        SettingsDivider()
                        SettingsRow(icon: "hand.raised", title: "Политика конфиденциальности", color: .kadroCharcoal) {}
                    }

                    // Danger zone
                    SettingsSection(title: "") {
                        Button {
                            showResetConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(width: 32)

                                Text("Сбросить онбординг")
                                    .font(.kadroBody)
                                    .foregroundColor(.red)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }

                    Text("Kadro © 2026")
                        .font(.kadroCaption)
                        .foregroundColor(.kadroWarmGray)
                        .padding(.vertical, 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.kadroIvory)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog(
            "Сбросить онбординг?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Сбросить", role: .destructive) {
                appState.hasCompletedOnboarding = false
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы увидите экран приветствия при следующем запуске.")
        }
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !title.isEmpty {
                Text(title.uppercased())
                    .font(.kadroCaption)
                    .foregroundColor(.kadroWarmGray)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 6)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(Color.kadroSoftWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.top, 8)
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var color: Color = .kadroCharcoal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.kadroBody)
                        .foregroundColor(.kadroCharcoal)

                    if let subtitle {
                        Text(subtitle)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.kadroSand)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Settings Toggle Row

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var color: Color = .kadroCharcoal
    @State private var isOn = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32)

            Text(title)
                .font(.kadroBody)
                .foregroundColor(.kadroCharcoal)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.kadroLime)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Settings Language Row

private struct SettingsLanguageRow: View {
    @State private var selectedLanguage = "Русский"
    private let languages = ["Русский", "English", "Türkçe"]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.kadroCharcoal)
                .frame(width: 32)

            Text("Язык")
                .font(.kadroBody)
                .foregroundColor(.kadroCharcoal)

            Spacer()

            Menu {
                ForEach(languages, id: \.self) { lang in
                    Button(lang) { selectedLanguage = lang }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedLanguage)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.kadroSand)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Divider

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 60)
            .background(Color.kadroSand)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AppState())
}
