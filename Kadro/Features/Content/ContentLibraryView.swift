//
//  ContentLibraryView.swift
//  Kadro
//
//  Content tab — editorial library of all content projects with filters
//

import SwiftUI
import SwiftData

struct ContentLibraryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentProject.updatedAt, order: .reverse) private var allProjects: [ContentProject]
    
    @State private var selectedFilter: ContentStatus?
    @State private var searchText: String = ""
    @State private var projectToDelete: ContentProject?
    @Environment(\.colorScheme) private var colorScheme
    
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
                
                // Custom Large Title Header
                HStack {
                    Text(L10n.Content.title)
                        .font(.custom("New York", size: 36).weight(.bold))
                        .foregroundColor(.kadroPrimary(for: colorScheme))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Search & Filter
                VStack(spacing: 12) {
                    searchBar
                    filterBar
                }
                .padding(.bottom, 8)
                
                // Content
                if allProjects.isEmpty {
                    emptyState
                } else if filteredProjects.isEmpty {
                    noResultsState
                } else {
                    contentList
                }
            }
            .background(Color.kadroBackground(for: colorScheme))
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.kadroWarmGray)
            
            TextField(L10n.Content.searchPlaceholder, text: $searchText)
                .font(.kadroBody)
                .foregroundColor(.kadroCharcoal)
                .submitLabel(.search)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.kadroWarmGray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.kadroCard(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" filter
                Button {
                    withAnimation(.snappy) {
                        selectedFilter = nil
                    }
                } label: {
                    Text(L10n.Content.filterAll)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedFilter == nil ? .kadroCharcoal : .kadroSecondary(for: colorScheme))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedFilter == nil ? Color.kadroLime : Color.kadroCard(for: colorScheme))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(selectedFilter == nil ? Color.clear : Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
                        )
                }
                
                // Other statuses
                ForEach(ContentStatus.allCases) { status in
                    Button {
                        withAnimation(.snappy) {
                            selectedFilter = selectedFilter == status ? nil : status
                        }
                    } label: {
                        Text(status.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedFilter == status ? .kadroCharcoal : .kadroSecondary(for: colorScheme))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == status ? Color.kadroLime : Color.kadroCard(for: colorScheme))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(selectedFilter == status ? Color.clear : Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
                            )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Content List
    
    private var contentList: some View {
        List {
            ForEach(filteredProjects) { project in
                editorialContentCard(for: project)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            projectToDelete = project
                        } label: {
                            Label(L10n.Content.deleteSwipe, systemImage: "trash")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            
            // Bottom padding spacer
            Color.clear
                .frame(height: 40)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .alert(
            L10n.Content.deleteConfirmTitle,
            isPresented: Binding(
                get: { projectToDelete != nil },
                set: { if !$0 { projectToDelete = nil } }
            ),
            presenting: projectToDelete
        ) { project in
            Button(L10n.Content.deleteConfirmAction, role: .destructive) {
                deleteProject(project)
            }
            Button(L10n.Common.cancel, role: .cancel) {
                projectToDelete = nil
            }
        } message: { project in
            Text(L10n.Content.deleteConfirmMessage(projectTitle: project.title.isEmpty ? L10n.Common.untitled : project.title))
        }
    }
    
    // MARK: - Card Design
    
    private func editorialContentCard(for project: ContentProject) -> some View {
        NavigationLink {
            ContentProjectDetailView(project: project)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Top header of card
                HStack(alignment: .center) {
                    Text(project.type.displayName.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .default))
                        .tracking(1.5)
                        .foregroundColor(.kadroWarmGray)
                    
                    Spacer()
                    
                    Text(project.updatedAt, style: .relative)
                        .font(.custom("New York", size: 12))
                        .foregroundColor(.kadroWarmGray)
                        .italic()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Body of card
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.title.isEmpty ? L10n.Common.untitled : project.title)
                            .font(.custom("New York", size: 20).weight(.medium))
                            .foregroundColor(.kadroPrimary(for: colorScheme))
                            .lineLimit(2)
                            .lineSpacing(2)
                        
                        if !project.rawInput.isEmpty {
                            Text(project.rawInput)
                                .font(.kadroCallout)
                                .foregroundColor(.kadroWarmGray)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Status dot
                    Circle()
                        .fill(statusColor(for: project.status))
                        .frame(width: 8, height: 8)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .background(Color.kadroCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Delete
    
    private func deleteProject(_ project: ContentProject) {
        withAnimation {
            modelContext.delete(project)
            try? modelContext.save()
        }
    }
    
    // MARK: - Empty States
    
    private var emptyState: some View {
        Spacer()
            .frame(maxHeight: .infinity)
            .overlay {
                VStack(spacing: 20) {
                    Image(systemName: "square.dashed")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundColor(.kadroWarmGray)
                    
                    Text(L10n.Content.emptyTitle)
                        .font(.custom("New York", size: 24).weight(.medium))
                        .foregroundColor(.kadroPrimary(for: colorScheme))

                    Text(L10n.Content.emptySubtitle)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button {
                        appState.openCreate()
                    } label: {
                        Text(L10n.Content.createContent)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.kadroPrimary(for: colorScheme))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.kadroCard(for: colorScheme))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.kadroBorderColor(for: colorScheme), lineWidth: 0.5)
                            )
                    }
                    .padding(.top, 8)
                }
            }
    }
    
    private var noResultsState: some View {
        Spacer()
            .frame(maxHeight: .infinity)
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.kadroWarmGray)
                    
                    Text(L10n.Content.noResultsTitle)
                        .font(.custom("New York", size: 20).weight(.medium))
                        .foregroundColor(.kadroPrimary(for: colorScheme))

                    Text(L10n.Content.noResultsSubtitle)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                        .multilineTextAlignment(.center)
                }
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
