//
//  CalendarView.swift
//  Kadro
//
//  Calendar tab — week/month view for content planning
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentProject.scheduledDate) private var scheduledProjects: [ContentProject]
    
    @State private var selectedDate: Date = .now
    @State private var viewMode: CalendarViewMode = .week
    
    private var calendar: Calendar { Calendar.current }
    
    private var weekDays: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private var projectsForSelectedDate: [ContentProject] {
        scheduledProjects.filter { project in
            guard let scheduled = project.scheduledDate else { return false }
            return calendar.isDate(scheduled, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode picker
                Picker("Режим", selection: $viewMode) {
                    ForEach(CalendarViewMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Week strip
                weekStrip
                
                Divider()
                    .foregroundColor(.kadroSand)
                
                // Day content
                ScrollView {
                    VStack(spacing: 16) {
                        if projectsForSelectedDate.isEmpty {
                            dayEmptyState
                        } else {
                            ForEach(projectsForSelectedDate) { project in
                                scheduledCard(for: project)
                            }
                        }
                        
                        // AI suggestions
                        aiSuggestions
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.kadroIvory)
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Week Strip
    
    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedDate = day
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(dayOfWeekShort(day))
                            .font(.kadroCaption)
                            .foregroundColor(.kadroWarmGray)
                        
                        Text("\(calendar.component(.day, from: day))")
                            .font(.kadroBodyMedium)
                            .foregroundColor(isSelected(day) ? .kadroCharcoal : .kadroCharcoal)
                        
                        // Content indicator dots
                        Circle()
                            .fill(hasContent(on: day) ? Color.kadroLime : Color.clear)
                            .frame(width: 6, height: 6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        isSelected(day)
                        ? RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.kadroLime.opacity(0.2))
                        : nil
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Scheduled Card
    
    private func scheduledCard(for project: ContentProject) -> some View {
        KadroCard {
            HStack(spacing: 12) {
                Image(systemName: project.type.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.kadroLime)
                    .frame(width: 36, height: 36)
                    .background(Color.kadroCharcoal)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.title.isEmpty ? "Без названия" : project.title)
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroCharcoal)
                    
                    if let date = project.scheduledDate {
                        Text(date, style: .time)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                    }
                }
                
                Spacer()
                
                KadroStatusBadge(
                    title: project.status.rawValue,
                    color: project.status == .scheduled ? .kadroLime : .kadroWarmGray
                )
            }
        }
    }
    
    // MARK: - Empty State
    
    private var dayEmptyState: some View {
        KadroCard {
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.kadroSand)
                
                Text("Нет контента на этот день")
                    .font(.kadroCallout)
                    .foregroundColor(.kadroWarmGray)
                
                KadroPrimaryButton(title: "Запланировать", action: {
                    appState.selectedTab = .create
                }, isFullWidth: false)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - AI Suggestions
    
    private var aiSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            KadroSectionHeader(title: "Подсказки")
            
            VStack(spacing: 8) {
                suggestionRow(
                    icon: "lightbulb",
                    text: "Среда без контента — добавьте обучающий пост"
                )
                
                suggestionRow(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Вчерашняя идея может стать каруселью"
                )
            }
        }
    }
    
    private func suggestionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.kadroLime)
                .frame(width: 32, height: 32)
                .background(Color.kadroCharcoal)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            Text(text)
                .font(.kadroFootnote)
                .foregroundColor(.kadroWarmGray)
            
            Spacer()
        }
        .padding(12)
        .background(Color.kadroSoftWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - Helpers
    
    private func dayOfWeekShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EE"
        return formatter.string(from: date).capitalized
    }
    
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func hasContent(on date: Date) -> Bool {
        scheduledProjects.contains { project in
            guard let scheduled = project.scheduledDate else { return false }
            return calendar.isDate(scheduled, inSameDayAs: date)
        }
    }
}

// MARK: - Calendar View Mode

enum CalendarViewMode: String, CaseIterable, Identifiable {
    case week = "Неделя"
    case month = "Месяц"
    
    var id: String { rawValue }
    var title: String { rawValue }
}

#Preview {
    CalendarView()
        .environment(AppState())
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
