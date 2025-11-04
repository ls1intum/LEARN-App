//
//  SearchHistoryView.swift
//  Master
//
//  Created by Minkyoung Park on 15.10.25.
//

import SwiftUI

struct SearchHistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var searchHistory: [SearchHistory] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var showingDeleteAlert = false
    @State private var historyToDelete: SearchHistory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Vergangene Suchanfragen")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 36/255, green: 37/255, blue: 44/255))
                .padding(.top, 40)
                .padding(.horizontal, 20)
            
            if appState.isLoggedIn {
                content
            } else {
                Spacer(minLength: 16)
                LoggedOutView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 0) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                        Text("Zurück")
                            .font(.system(size: 14))
                    }
                    .fixedSize()
                }
                .foregroundColor(.blue)
                .buttonStyle(.plain)
            }
        }
        .task { await loadSearchHistory() }
        .onChange(of: appState.userEmail) {
            Task { await loadSearchHistory() }
        }
        .onChange(of: appState.isLoggedIn) {
            if appState.isLoggedIn { Task { await loadSearchHistory() } }
            else { searchHistory = [] }
        }
        .alert("Suchverlauf löschen", isPresented: $showingDeleteAlert) {
            Button("Löschen", role: .destructive) {
                if let history = historyToDelete {
                    Task { await deleteSearchHistory(history) }
                }
            }
            Button("Abbrechen", role: .cancel) {
                historyToDelete = nil
            }
        } message: {
            Text("Möchtest du diesen Suchverlauf wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let err = errorText {
            VStack(spacing: 8) {
                Spacer()
                Text("Fehler beim Laden").font(.headline)
                Text(err).font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)
                Button("Erneut versuchen") { Task { await loadSearchHistory() } }
                    .buttonStyle(CurvedBorderedButtonStyle())
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isLoading {
            VStack(spacing: 12) {
                Spacer()
                ProgressView()
                Text("Lade Suchverlauf…").font(.footnote).foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if searchHistory.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "clock.arrow.circlepath")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 138/255, green: 180/255, blue: 248/255))
                Text("Du hast noch keine\nSuchanfragen erstellt.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(searchHistory.prefix(20))) { search in
                        NavigationLink(destination: SearchHistoryDetailView(search: search)) {
                            SearchHistoryCardView(
                                search: search,
                                onDelete: {
                                    historyToDelete = search
                                    showingDeleteAlert = true
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .refreshable { await loadSearchHistory() }
        }
    }
    
    // MARK: - Data
    
    @MainActor
    private func loadSearchHistory() async {
        guard appState.isLoggedIn else { return }
        isLoading = true; errorText = nil
        defer { isLoading = false }
        
        do {
            let client = APIClient()
            let svc = LiveActivitiesAPI(api: client)
            searchHistory = try await svc.getSearchHistory()
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }
    
    @MainActor
    private func deleteSearchHistory(_ history: SearchHistory) async {
        do {
            let client = APIClient()
            let svc = LiveActivitiesAPI(api: client)
            let _ = try await svc.deleteSearchHistory(historyId: history.id)
            
            // Remove from local array
            searchHistory.removeAll { $0.id == history.id }
            historyToDelete = nil
            
        } catch {
            print("Error deleting search history: \(error)")
            errorText = "Fehler beim Löschen des Suchverlaufs"
        }
    }
}

struct SearchHistoryCardView: View {
    let search: SearchHistory
    let onDelete: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }
    
    private func truncatedText(_ text: String, maxItems: Int) -> String {
        let items = text.components(separatedBy: ", ")
        if items.count <= maxItems {
            return text
        } else {
            let firstItems = Array(items.prefix(maxItems))
            let remainingCount = items.count - maxItems
            return firstItems.joined(separator: ", ") + " +\(remainingCount)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with date and delete button
            HStack {
                Text(dateFormatter.string(from: search.createdAt))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
            
            // Main search criteria - more prominent
            VStack(alignment: .leading, spacing: 12) {
                // Grade and Duration as primary info
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2")
                            .foregroundColor(AppColors.primary)
                            .font(.system(size: 16))
                        Text(search.searchCriteria.gradeText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.title)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundColor(AppColors.primary)
                            .font(.system(size: 16))
                        Text(search.searchCriteria.durationText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.title)
                    }
                    
                    Spacer()
                }
                
                
                // Topics and Devices as secondary info
                VStack(alignment: .leading, spacing: 6) {
                    if !search.searchCriteria.topicsText.isEmpty && search.searchCriteria.topicsText != "Alle Themen" {
                        HStack(spacing: 6) {
                            Image(systemName: "book.closed")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            Text(truncatedText(search.searchCriteria.topicsText, maxItems: 2))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    if !search.searchCriteria.devicesText.isEmpty && search.searchCriteria.devicesText != "Alle Geräte" {
                        HStack(spacing: 6) {
                            Image(systemName: "desktopcomputer")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            Text(truncatedText(search.searchCriteria.devicesText, maxItems: 2))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
    }
}

struct SearchHistoryDetailView: View {
    let search: SearchHistory
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        PlanStepView(
            selectedGrade: search.searchCriteria.targetAge.map { $0 - 5 }, // Convert age to grade (6->1, 7->2, etc.)
            selectedDurationMinutes: search.searchCriteria.targetDuration ?? 30,
            selectedDevices: Set(search.searchCriteria.availableResources?.compactMap { Device(rawValue: $0) } ?? []),
            selectedTopics: Set(search.searchCriteria.preferredTopics?.compactMap { Topic(rawValue: $0) } ?? []),
            onRestart: { dismiss() },
            onBack: { dismiss() },
            showProgressBar: .constant(true),
            useNavigationStack: false
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 0) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                        Text("Zurück")
                            .font(.system(size: 14))
                    }
                    .fixedSize()
                }
                .foregroundColor(.blue)
                .buttonStyle(.plain)
            }
        }
    }
}
