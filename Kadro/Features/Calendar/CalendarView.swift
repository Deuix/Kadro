//
//  CalendarView.swift
//  Kadro
//
//  Calendar tab — editorial planner for scheduling and weekly planning
//

import SwiftUI
import SwiftData

private struct CalendarScheduleRequest: Identifiable {
    let id = UUID()
    let project: ContentProject
    let initialDate: Date
    let title: String
}

struct CalendarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentProject.updatedAt, order: .reverse) private var allProjects: [ContentProject]
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedDate: Date = .now
    @State private var viewMode: CalendarViewMode = .week
    @State private var scheduleRequest: CalendarScheduleRequest?
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }
    
    private var scheduledProjects: [ContentProject] {
        allProjects
            .filter { $0.scheduledDate != nil }
            .sorted { ($0.scheduledDate ?? .distantPast) < ($1.scheduledDate ?? .distantPast) }
    }
    
    private var readyDrafts: [ContentProject] {
        allProjects.filter { $0.status == .ready && $0.scheduledDate == nil }
    }
    
    private var weekDays: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private var monthGridDays: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)) else {
            return []
        }
        
        let dayRange = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<2
        let weekday = calendar.component(.weekday, from: monthStart)
        let leadingEmptyDays = (weekday - calendar.firstWeekday + 7) % 7
        
        var result: [Date?] = Array(repeating: nil, count: leadingEmptyDays)
        result.append(contentsOf: dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        })
        
        while result.count % 7 != 0 {
            result.append(nil)
        }
        
        return result
    }
    
    private var projectsForSelectedDate: [ContentProject] {
        scheduledProjects.filter { project in
            guard let scheduled = project.scheduledDate else { return false }
            return calendar.isDate(scheduled, inSameDayAs: selectedDate)
        }
    }
    
    private var scheduledThisWeek: [ContentProject] {
        scheduledProjects.filter { project in
            guard let scheduled = project.scheduledDate else { return false }
            return weekDays.contains(where: { calendar.isDate($0, inSameDayAs: scheduled) })
        }
    }
    
    private var scheduledThisWeekCount: Int {
        scheduledThisWeek.count
    }
    
    private var emptyDaysThisWeekCount: Int {
        weekDays.filter { !hasContent(on: $0) }.count
    }
    
    private var readyDraftCount: Int {
        readyDrafts.count
    }
    
    private var firstReadyDraft: ContentProject? {
        readyDrafts.first
    }
    
    private var selectedDateScheduleButtonTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return L10n.Calendar.scheduleToday
        }
        if calendar.isDateInTomorrow(selectedDate) {
            return L10n.Calendar.scheduleTomorrow
        }
        return L10n.Calendar.scheduleThisDay
    }
    
    private var formattedMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate).capitalized
    }

    private var formattedWeekTitle: String {
        guard let first = weekDays.first, let last = weekDays.last else { return formattedMonthTitle }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: first)) — \(formatter.string(from: last))"
    }
    
    private var localizedWeekdaySymbols: [String] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let symbols = cal.shortStandaloneWeekdaySymbols
        let shifted = Array(symbols[1...]) + [symbols[0]]
        return shifted.map { $0.uppercased() }
    }

    private var bodyBackground: Color {
        Color.kadroBackground(for: colorScheme)
    }
    
    private var cardBackground: Color {
        Color.kadroCard(for: colorScheme)
    }
    
    private var cardBorder: Color {
        Color.kadroBorderColor(for: colorScheme)
    }
    
    private var primaryText: Color {
        Color.kadroPrimary(for: colorScheme)
    }
    
    private var secondaryText: Color {
        Color.kadroSecondary(for: colorScheme)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                plannerStats
                periodNavigator
                
                if viewMode == .week {
                    weekStrip
                } else {
                    monthGrid
                }
                
                Divider()
                    .overlay(cardBorder)
                    .padding(.vertical, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        selectedDayAgendaSection
                        readyDraftsSection
                        plannerInsightsSection
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(bodyBackground)
            .navigationBarHidden(true)
            .sheet(item: $scheduleRequest) { request in
                CalendarScheduleSheet(
                    title: request.title,
                    initialDate: request.initialDate
                ) { date in
                    applySchedule(date, to: request.project)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Calendar.title)
                    .font(.custom("New York", size: 36).weight(.bold))
                    .foregroundColor(primaryText)
                Text(viewMode == .week ? formattedWeekTitle : formattedMonthTitle)
                    .font(.custom("New York", size: 20).weight(.medium))
                    .foregroundColor(secondaryText)
            }
            Spacer()
            Button {
                appState.openCreate()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(primaryText)
                    .frame(width: 44, height: 44)
                    .background(cardBackground)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(cardBorder, lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    private var plannerStats: some View {
        HStack(spacing: 12) {
            plannerStatCard(value: "\(scheduledThisWeekCount)", title: L10n.Calendar.statScheduledTitle, subtitle: L10n.Calendar.statScheduledSubtitle)
            plannerStatCard(value: "\(emptyDaysThisWeekCount)", title: L10n.Calendar.statFreeTitle, subtitle: L10n.Calendar.statFreeSubtitle)
            plannerStatCard(value: "\(readyDraftCount)", title: L10n.Calendar.statReadyTitle, subtitle: L10n.Calendar.statReadySubtitle)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    private func plannerStatCard(value: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.custom("New York", size: 28).weight(.medium))
                .foregroundColor(primaryText)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(secondaryText)
            Text(subtitle)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(secondaryText.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(cardBorder, lineWidth: 0.5)
        )
    }
    
    // MARK: - Period Navigation
    
    private var periodNavigator: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Button {
                    shiftPeriod(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryText)
                        .frame(width: 36, height: 36)
                        .background(cardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(cardBorder, lineWidth: 0.5))
                }
                
                Button {
                    selectedDate = .now
                } label: {
                    Text(viewMode == .week ? formattedWeekTitle : formattedMonthTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryText)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(cardBackground)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(cardBorder, lineWidth: 0.5))
                }
                
                Button {
                    shiftPeriod(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryText)
                        .frame(width: 36, height: 36)
                        .background(cardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(cardBorder, lineWidth: 0.5))
                }
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                ForEach(CalendarViewMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                            viewMode = mode
                        }
                    } label: {
                        Text(mode.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(viewMode == mode ? .kadroCharcoal : secondaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(viewMode == mode ? Color.kadroLime : cardBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(viewMode == mode ? Color.clear : cardBorder, lineWidth: 0.5)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    // MARK: - Week / Month
    
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
                            .foregroundColor(selected ? (today ? .kadroLime : .kadroSoftWhite) : secondaryText)
                        
                        Text("\(calendar.component(.day, from: day))")
                            .font(.custom("New York", size: 18).weight(selected ? .semibold : .regular))
                            .foregroundColor(selected ? (today ? .kadroLime : .kadroSoftWhite) : primaryText)
                        
                        Circle()
                            .fill(hasContent(on: day) ? (selected ? .kadroLime : primaryText) : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selected ? Color.kadroCharcoal : Color.clear)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(today && !selected ? cardBorder : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var monthGrid: some View {
        VStack(spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
                ForEach(localizedWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(secondaryText)
                        .frame(maxWidth: .infinity)
                }
                
                ForEach(Array(monthGridDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                selectedDate = day
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.system(size: 14, weight: isSelected(day) ? .semibold : .regular))
                                    .foregroundColor(isSelected(day) ? .kadroSoftWhite : primaryText)
                                Circle()
                                    .fill(hasContent(on: day) ? (isSelected(day) ? .kadroLime : primaryText) : Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(isSelected(day) ? Color.kadroCharcoal : cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(calendar.isDateInToday(day) && !isSelected(day) ? cardBorder : Color.clear, lineWidth: 1)
                            )
                        }
                    } else {
                        Color.clear
                            .frame(height: 46)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Sections
    
    private var selectedDayAgendaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFormattedForHeader(selectedDate))
                        .font(.custom("New York", size: 22).weight(.medium))
                        .foregroundColor(primaryText)
                    Text(agendaSubtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryText)
                }
                Spacer()
                Button {
                    appState.openCreate()
                } label: {
                    Text(L10n.Common.create)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(cardBackground)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(cardBorder, lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 24)

            if projectsForSelectedDate.isEmpty {
                dayEmptyState
            } else {
                VStack(spacing: 16) {
                    ForEach(projectsForSelectedDate) { project in
                        scheduledAgendaCard(for: project)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var dayEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(secondaryText)
            
            Text(L10n.Calendar.noContent)
                .font(.custom("New York", size: 20).weight(.medium))
                .foregroundColor(primaryText)

            Text(firstReadyDraft == nil
                 ? L10n.Calendar.emptyHintNoDrafts
                 : L10n.Calendar.emptyHintHasDraft)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            HStack(spacing: 12) {
                if let firstReadyDraft {
                    Button {
                        openSchedule(for: firstReadyDraft, initialDate: defaultScheduleDate(for: selectedDate))
                    } label: {
                        Text(L10n.Calendar.scheduleReadyDraft)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryText)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(cardBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(cardBorder, lineWidth: 0.5))
                    }
                }
                
                Button {
                    appState.openCreate()
                } label: {
                    Text(L10n.Calendar.createContent)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.kadroCharcoal)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.kadroLime)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(bodyBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(cardBorder, style: StrokeStyle(lineWidth: 1, dash: [6]))
        )
        .padding(.horizontal, 24)
    }
    
    private func scheduledAgendaCard(for project: ContentProject) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .trailing, spacing: 3) {
                if let date = project.scheduledDate {
                    Text(timeString(from: date))
                        .font(.custom("New York", size: 16).weight(.medium))
                        .foregroundColor(primaryText)
                    Text(project.status.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(width: 64, alignment: .trailing)
            
            ZStack(alignment: .topTrailing) {
                NavigationLink {
                    ContentProjectDetailView(project: project)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Text(project.type.displayName.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.4)
                                .foregroundColor(secondaryText)
                            Spacer()
                            Circle()
                                .fill(statusColor(for: project.status))
                                .frame(width: 8, height: 8)
                        }
                        
                        Text(project.title.isEmpty ? L10n.Common.untitled : project.title)
                            .font(.custom("New York", size: 20).weight(.medium))
                            .foregroundColor(primaryText)
                            .lineLimit(2)
                        
                        if !project.rawInput.isEmpty {
                            Text(project.rawInput)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(secondaryText)
                                .lineLimit(2)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(cardBorder, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                
                Menu {
                    Button(L10n.Calendar.changeDate) {
                        openSchedule(for: project, initialDate: project.scheduledDate ?? defaultScheduleDate(for: selectedDate))
                    }
                    if project.status != .published {
                        Button(L10n.Calendar.markPublished) {
                            markPublished(project)
                        }
                    }
                    Button(L10n.Calendar.removeFromCalendar, role: .destructive) {
                        unschedule(project)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(secondaryText)
                        .frame(width: 34, height: 34)
                        .background(cardBackground)
                        .clipShape(Circle())
                }
                .padding(12)
            }
        }
    }
    
    private var readyDraftsSection: some View {
        Group {
            if !readyDrafts.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ready drafts")
                                .font(.custom("New York", size: 22).weight(.medium))
                                .foregroundColor(primaryText)
                            Text(L10n.Calendar.readyDraftsHint)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(secondaryText)
                        }
                        Spacer()
                        if emptyDaysThisWeekCount > 0 {
                            Button {
                                autoPlanWeek()
                            } label: {
                                Text(L10n.Calendar.fillWeek)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.kadroCharcoal)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.kadroLime)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(readyDrafts) { project in
                                readyDraftCard(for: project)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }
    
    private func readyDraftCard(for project: ContentProject) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(project.type.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundColor(secondaryText)
                
                Text(project.title.isEmpty ? L10n.Common.untitled : project.title)
                    .font(.custom("New York", size: 18).weight(.medium))
                    .foregroundColor(primaryText)
                    .lineLimit(2)
                
                if !project.rawInput.isEmpty {
                    Text(project.rawInput)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(secondaryText)
                        .lineLimit(3)
                }
            }
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    plannerActionPill(title: selectedDateScheduleButtonTitle) {
                        applyQuickSchedule(project, for: selectedDate)
                    }
                    plannerActionPill(title: L10n.Calendar.tomorrowAction) {
                        applyQuickSchedule(project, for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                    }
                }
                
                HStack(spacing: 8) {
                    plannerActionPill(title: L10n.Calendar.pickDate) {
                        openSchedule(for: project, initialDate: defaultScheduleDate(for: selectedDate))
                    }
                    NavigationLink {
                        ContentProjectDetailView(project: project)
                    } label: {
                        Text(L10n.Calendar.open)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(bodyBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(cardBorder, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(width: 290, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(cardBorder, lineWidth: 0.5)
        )
    }
    
    private func plannerActionPill(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(bodyBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(cardBorder, lineWidth: 0.5))
        }
    }
    
    private var plannerInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Calendar.insightsSectionTitle)
                .font(.custom("New York", size: 22).weight(.medium))
                .foregroundColor(primaryText)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if let firstReadyDraft, projectsForSelectedDate.isEmpty {
                        plannerInsightCard(
                            icon: "calendar.badge.plus",
                            title: L10n.Calendar.insightFreeSlotTitle,
                            text: L10n.Calendar.insightFreeSlotText,
                            color: Color.kadroCharcoal,
                            textColor: .kadroSoftWhite,
                            buttonTitle: L10n.Calendar.insightFreeSlotButton
                        ) {
                            openSchedule(for: firstReadyDraft, initialDate: defaultScheduleDate(for: selectedDate))
                        }
                    }
                    
                    if readyDraftCount > 0 && emptyDaysThisWeekCount > 0 {
                        plannerInsightCard(
                            icon: "sparkles",
                            title: L10n.Calendar.insightAutoPlanTitle,
                            text: L10n.Calendar.insightAutoPlanText,
                            color: cardBackground,
                            textColor: primaryText,
                            buttonTitle: L10n.Calendar.insightAutoPlanButton
                        ) {
                            autoPlanWeek()
                        }
                    }
                    
                    if scheduledThisWeekCount == 0 {
                        plannerInsightCard(
                            icon: "lightbulb",
                            title: L10n.Calendar.insightEmptyWeekTitle,
                            text: L10n.Calendar.insightEmptyWeekText,
                            color: Color.kadroCharcoal,
                            textColor: .kadroSoftWhite,
                            buttonTitle: L10n.Calendar.insightEmptyWeekButton
                        ) {
                            appState.openCreate(outputType: .post)
                        }
                    }
                    
                    if scheduledThisWeek.filter({ $0.type == .carousel }).count >= 2 && scheduledThisWeek.filter({ $0.type == .post }).isEmpty {
                        plannerInsightCard(
                            icon: "text.quote",
                            title: L10n.Calendar.insightLightFormatTitle,
                            text: L10n.Calendar.insightLightFormatText,
                            color: cardBackground,
                            textColor: primaryText,
                            buttonTitle: L10n.Calendar.insightLightFormatButton
                        ) {
                            appState.openCreate(outputType: .post)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func plannerInsightCard(icon: String, title: String, text: String, color: Color, textColor: Color, buttonTitle: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(textColor)
            
            Text(title)
                .font(.custom("New York", size: 18).weight(.medium))
                .foregroundColor(textColor)
            
            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(textColor.opacity(0.82))
                .lineLimit(4)
                .lineSpacing(2)
            
            Spacer()
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color == Color.kadroCharcoal ? .kadroCharcoal : primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(color == Color.kadroCharcoal ? Color.kadroLime : bodyBackground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(color == Color.kadroCharcoal ? Color.clear : cardBorder, lineWidth: 0.5)
                    )
            }
        }
        .padding(20)
        .frame(width: 230, height: 190, alignment: .topLeading)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(color == cardBackground ? cardBorder : Color.clear, lineWidth: 0.5)
        )
    }
    
    // MARK: - Helpers
    
    private var agendaSubtitle: String {
        if projectsForSelectedDate.isEmpty {
            return L10n.Calendar.nothingScheduled
        }
        let count = projectsForSelectedDate.count
        return count == 1 ? L10n.Calendar.agendaOnePost : L10n.Calendar.agendaPostsCount(count)
    }
    
    private func shiftPeriod(by value: Int) {
        let component: Calendar.Component = viewMode == .week ? .weekOfYear : .month
        if let shifted = calendar.date(byAdding: component, value: value, to: selectedDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                selectedDate = shifted
            }
        }
    }
    
    private func openSchedule(for project: ContentProject, initialDate: Date) {
        scheduleRequest = CalendarScheduleRequest(
            project: project,
            initialDate: initialDate,
            title: project.title.isEmpty ? L10n.Calendar.schedulePlaceholder : project.title
        )
    }
    
    private func applyQuickSchedule(_ project: ContentProject, for day: Date) {
        applySchedule(defaultScheduleDate(for: day), to: project)
    }
    
    private func applySchedule(_ date: Date, to project: ContentProject) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            project.scheduledDate = date
            if project.status != .published {
                project.status = .scheduled
            }
            try? modelContext.save()
        }
    }
    
    private func unschedule(_ project: ContentProject) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            project.scheduledDate = nil
            if project.status != .published {
                project.status = .ready
            }
            try? modelContext.save()
        }
    }
    
    private func markPublished(_ project: ContentProject) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            if project.scheduledDate == nil {
                project.scheduledDate = defaultScheduleDate(for: selectedDate)
            }
            project.status = .published
            try? modelContext.save()
        }
    }
    
    private func autoPlanWeek() {
        let emptyDays = weekDays.filter { !hasContent(on: $0) }
        guard !emptyDays.isEmpty else { return }
        
        for (index, pair) in zip(emptyDays, readyDrafts).enumerated() {
            let (day, project) = pair
            let hour = 10 + ((index % 3) * 3)
            applySchedule(defaultScheduleDate(for: day, hour: hour), to: project)
        }
    }
    
    private func defaultScheduleDate(for day: Date, hour: Int = 10, minute: Int = 0) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? day
    }
    
    private func dayOfWeekShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "E"
        return formatter.string(from: date).uppercased()
    }
    
    private func dateFormattedForHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        if calendar.isDateInToday(date) {
            return L10n.Calendar.todayPrefix + formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            return L10n.Calendar.tomorrowPrefix + formatter.string(from: date)
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
    
    private func statusColor(for status: ContentStatus) -> Color {
        switch status {
        case .draft: return .kadroWarmGray
        case .ready: return .kadroSuccess
        case .scheduled: return .kadroLime
        case .published: return .kadroCharcoal
        }
    }
}

// MARK: - Calendar View Mode

enum CalendarViewMode: String, CaseIterable, Identifiable {
    case week = "Неделя"
    case month = "Месяц"
    
    var id: String { rawValue }
}

// MARK: - Schedule Sheet

private struct CalendarScheduleSheet: View {
    let title: String
    let onSave: (Date) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: Date
    @State private var selectedTime: Date
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }
    
    init(title: String, initialDate: Date, onSave: @escaping (Date) -> Void) {
        self.title = title
        self.onSave = onSave
        _selectedDay = State(initialValue: initialDate)
        _selectedTime = State(initialValue: initialDate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Calendar.scheduleSheetTitle)
                            .font(.custom("New York", size: 22).weight(.medium))
                            .foregroundColor(.kadroCharcoal)
                        Text(L10n.Calendar.scheduleSheetSubtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.kadroWarmGray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text(L10n.Calendar.dateLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.kadroWarmGray)
                        DatePicker(
                            "",
                            selection: $selectedDay,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                    }
                    .padding(16)
                    .background(Color.kadroSoftWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.kadroSand, lineWidth: 0.5)
                    )
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text(L10n.Calendar.timeLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.kadroWarmGray)
                        DatePicker(
                            "",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 120)
                    }
                    .padding(16)
                    .background(Color.kadroSoftWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.kadroSand, lineWidth: 0.5)
                    )
                }
                .padding(20)
            }
            .background(Color.kadroIvory)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                    .foregroundColor(.kadroWarmGray)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        onSave(combinedDate)
                        dismiss()
                    }
                    .foregroundColor(.kadroLime)
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }
    
    private var combinedDate: Date {
        let day = calendar.dateComponents([.year, .month, .day], from: selectedDay)
        let time = calendar.dateComponents([.hour, .minute], from: selectedTime)
        return calendar.date(from: DateComponents(
            year: day.year,
            month: day.month,
            day: day.day,
            hour: time.hour,
            minute: time.minute
        )) ?? selectedDay
    }
}

#Preview {
    CalendarView()
        .environment(AppState())
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
