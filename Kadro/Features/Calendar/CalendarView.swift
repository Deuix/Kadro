//
//  CalendarView.swift
//  Kadro
//
//  Calendar tab — week view for content planning with editorial styling
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
    
    private var thisMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL"
        return formatter.string(from: selectedDate).capitalized
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Планирование")
                            .font(.custom("New York", size: 36).weight(.bold))
                            .foregroundColor(.kadroCharcoal)
                        
                        Text(thisMonthString)
                            .font(.custom("New York", size: 20).weight(.medium))
                            .foregroundColor(.kadroWarmGray)
                    }
                    Spacer()
                    
                    // Add quick button
                    Button {
                        appState.openCreate()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.kadroCharcoal)
                            .frame(width: 44, height: 44)
                            .background(Color.kadroSoftWhite)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.kadroSand, lineWidth: 0.5)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Week strip
                weekStrip
                
                Divider()
                    .overlay(Color.kadroSand)
                    .padding(.vertical, 16)
                
                // Day content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        HStack {
                            Text(dateFormattedForHeader(selectedDate))
                                .font(.custom("New York", size: 22).weight(.medium))
                                .foregroundColor(.kadroCharcoal)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        if projectsForSelectedDate.isEmpty {
                            dayEmptyState
                        } else {
                            VStack(spacing: 16) {
                                ForEach(projectsForSelectedDate) { project in
                                    editorialScheduledCard(for: project)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // AI suggestions
                        aiSuggestions
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Color.kadroIvory)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Week Strip
    
    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(weekDays, id: \.self) { day in
                let selected = isSelected(day)
                let today = calendar.isDateInToday(day)
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedDate = day
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(dayOfWeekShort(day))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(selected ? (today ? .kadroLime : .kadroSoftWhite) : .kadroWarmGray)
                        
                        Text("\(calendar.component(.day, from: day))")
                            .font(.custom("New York", size: 18).weight(selected ? .semibold : .regular))
                            .foregroundColor(selected ? (today ? .kadroLime : .kadroSoftWhite) : .kadroCharcoal)
                        
                        // Content indicator dots
                        Circle()
                            .fill(hasContent(on: day) ? (selected ? .kadroLime : .kadroCharcoal) : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selected
                        ? Color.kadroCharcoal
                        : Color.clear
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(today && !selected ? Color.kadroSand : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Scheduled Card
    
    private func editorialScheduledCard(for project: ContentProject) -> some View {
        HStack(spacing: 16) {
            // Time column
            VStack(alignment: .trailing, spacing: 2) {
                if let date = project.scheduledDate {
                    Text(timeString(from: date))
                        .font(.custom("New York", size: 16).weight(.medium))
                        .foregroundColor(.kadroCharcoal)
                    Text("GMT+4") // Mock timezone or handle properly
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.kadroWarmGray)
                }
            }
            .frame(width: 50, alignment: .trailing)
            
            // Content Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(project.type.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .default))
                        .tracking(1.5)
                        .foregroundColor(.kadroWarmGray)
                    
                    Spacer()
                    
                    // Status dot
                    Circle()
                        .fill(project.status == .scheduled ? Color.kadroLime : Color.kadroWarmGray)
                        .frame(width: 8, height: 8)
                }
                
                Text(project.title.isEmpty ? "Без названия" : project.title)
                    .font(.custom("New York", size: 20).weight(.medium))
                    .foregroundColor(.kadroCharcoal)
                    .lineLimit(2)
                    .lineSpacing(2)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.kadroSoftWhite)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.kadroSand, lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Empty State
    
    private var dayEmptyState: some View {
        Button {
            appState.openCreate()
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.kadroWarmGray)
                
                Text("День свободен")
                    .font(.custom("New York", size: 20).weight(.medium))
                    .foregroundColor(.kadroCharcoal)
                
                Text("Запланировать контент")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.kadroCharcoal)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.kadroSoftWhite)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.kadroSand, lineWidth: 0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(Color.kadroIvory)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.kadroSand, style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }
    
    // MARK: - AI Suggestions
    
    private var aiSuggestions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Советы")
                .font(.custom("New York", size: 22).weight(.medium))
                .foregroundColor(.kadroCharcoal)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    editorialSuggestionCard(
                        icon: "lightbulb",
                        title: "Среда пустует",
                        text: "Добавьте небольшой обучающий пост для вовлечения",
                        color: .kadroCharcoal,
                        textColor: .kadroIvory
                    )
                    
                    editorialSuggestionCard(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Ресайкл",
                        text: "Вчерашняя история отлично подойдет для карусели",
                        color: .kadroSoftWhite,
                        textColor: .kadroCharcoal
                    )
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 16)
    }
    
    private func editorialSuggestionCard(icon: String, title: String, text: String, color: Color, textColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(textColor)
            
            Text(title)
                .font(.custom("New York", size: 18).weight(.medium))
                .foregroundColor(textColor)
            
            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(textColor.opacity(0.8))
                .lineLimit(3)
                .lineSpacing(2)
        }
        .padding(20)
        .frame(width: 200, height: 160, alignment: .topLeading)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(color == .kadroSoftWhite ? Color.kadroSand : Color.clear, lineWidth: 0.5)
        )
    }
    
    // MARK: - Helpers
    
    private func dayOfWeekShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "E"
        return formatter.string(from: date).uppercased()
    }
    
    private func dateFormattedForHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        if calendar.isDateInToday(date) {
            return "Сегодня, " + formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            return "Завтра, " + formatter.string(from: date)
        }
        return formatter.string(from: date)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
