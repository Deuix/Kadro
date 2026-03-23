//
//  ContentLibraryView.swift
//  Kadro
//
//  Content tab — library of all content projects with filters
//

import SwiftUI
import SwiftData

struct ContentLibraryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentProject.updatedAt, order: .reverse) private var allProjects: [ContentProject]
    
    @State private var selectedFilter: ContentStatus?
    @State private var searchText: String = ""
    
    private var filteredProjects: [ContentProject] {
        var result = allProjects
        
        if let filter = selectedFilter {
            result = result.filter { $0.status == filter }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.rawInput.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                filterBar
                
                // Content
                if allProjects.isEmpty {
                    emptyState
                } else if filteredProjects.isEmpty {
                    noResultsState
                } else {
                    contentList
                }
            }
            .background(Color.kadroIvory)
            .navigationTitle("Контент")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Поиск по названию")
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                KadroChip(title: "Все", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                
                ForEach(ContentStatus.allCases) { status in
                    KadroChip(title: status.rawValue, isSelected: selectedFilter == status) {
                        selectedFilter = selectedFilter == status ? nil : status
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Content List
    
    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredProjects) { project in
                    contentCard(for: project)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }
    
    private func contentCard(for project: ContentProject) -> some View {
        KadroCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
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
                            .lineLimit(1)
                        
                        Text(project.type.rawValue + " · " + project.platform.rawValue)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                    }
                    
                    Spacer()
                    
                    KadroStatusBadge(
                        title: project.status.rawValue,
                        color: statusColor(for: project.status)
                    )
                }
                
                if !project.rawInput.isEmpty {
                    Text(project.rawInput)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(project.updatedAt, style: .relative)
                        .font(.kadroCaption)
                        .foregroundColor(.kadroWarmGray)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.kadroSand)
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyState: some View {
        Spacer()
            .frame(maxHeight: .infinity)
            .overlay {
                KadroEmptyState(
                    icon: "doc.text.magnifyingglass",
                    title: "Пока нет контента",
                    subtitle: "Создайте свой первый пост, карусель или сценарий",
                    buttonTitle: "Создать"
                ) {
                    appState.selectedTab = .create
                }
            }
    }
    
    private var noResultsState: some View {
        Spacer()
            .frame(maxHeight: .infinity)
            .overlay {
                KadroEmptyState(
                    icon: "magnifyingglass",
                    title: "Ничего не найдено",
                    subtitle: "Попробуйте изменить фильтр или поисковый запрос"
                )
            }
    }
    
    // MARK: - Helpers
    
    private func statusColor(for status: ContentStatus) -> Color {
        switch status {
        case .draft: return .kadroWarmGray
        case .ready: return .kadroSuccess
        case .scheduled: return .kadroLime
        case .published: return .kadroCharcoal
        }
    }
}

#Preview {
    ContentLibraryView()
        .environment(AppState())
        .modelContainer(for: [ContentProject.self, BrandProfile.self], inMemory: true)
}
