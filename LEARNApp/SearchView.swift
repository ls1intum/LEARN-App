//
//  SearchView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI

// MARK: - Duration Filter

enum DurationFilter: String, CaseIterable, Identifiable {
    case all = "Alle"
    case under30 = "<30min"
    case under45 = "<45min"
    case under60 = "<60min"
    case under90 = "<90min"
    case under120 = "<120min"

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .all:      return "Alle Dauern"
        case .under30:  return "< 30 Min"
        case .under45:  return "< 45 Min"
        case .under60:  return "< 60 Min"
        case .under90:  return "< 90 Min"
        case .under120: return "< 120 Min"
        }
    }

    func includes(duration: Int) -> Bool {
        switch self {
        case .all:      return true
        case .under30:  return duration > 0 && duration < 30
        case .under45:  return duration > 0 && duration < 45
        case .under60:  return duration > 0 && duration < 60
        case .under90:  return duration > 0 && duration < 90
        case .under120: return duration > 0 && duration < 120
        }
    }
}

// MARK: - View

struct SearchView: View {
    @EnvironmentObject var appState: AppState

    // Data
    @State private var materials: [Material] = []
    @State private var visibleCount: Int = 10                // Show first 10, then load more

    // Filters/UI
    @State private var searchText: String = ""
    @State private var selectedGrade: Int? = nil
    @State private var selectedTopic: String? = nil          // German label of Topic
    @State private var selectedDevice: String? = nil         // German label of Device
    @State private var selectedDuration: DurationFilter = .all
    @State private var showFilters = false                   // toggle full filter panel

    // Status
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var showingLoginAlert = false

    // Count how many filters are currently active (for the button badge)
    private var filtersActiveCount: Int {
        var c = 0
        if selectedGrade != nil { c += 1 }
        if selectedDuration != .all { c += 1 }
        if selectedDevice != nil { c += 1 }
        if selectedTopic != nil { c += 1 }
        return c
    }

    // Summary line when collapsed
    private var filterSummaryText: String {
        let gradeText = selectedGrade.map { "Klasse: \($0)" } ?? "Klasse: Alle"
        let durationText = (selectedDuration == .all) ? "Dauer: Alle" : "Dauer: \(selectedDuration.label)"
        let deviceText = "Gerät: " + (selectedDevice ?? "Alle")
        let topicText  = "Thema: " + (selectedTopic ?? "Alle")
        return [gradeText, durationText, deviceText, topicText].joined(separator: " • ")
    }

    // Filtering
    private var filteredMaterials: [Material] {
        // Since materials already contain German labels, we can compare directly
        let matchesGrade: (Material) -> Bool = { m in
            guard let sel = selectedGrade else { return true }

            if let gMin = m.gradeMin, let gMax = m.gradeMax {
                return sel >= gMin && sel <= gMax
            } else {
                // Fallback auf legacy single grade
                return m.grade == sel
            }
        }

        return materials.filter {
            matchesGrade($0) &&
            (selectedDevice == nil || $0.devices.contains(where: { $0.equalsCaseInsensitive(selectedDevice!) })) &&
            (selectedTopic == nil || $0.topics.contains(where: { $0.equalsCaseInsensitive(selectedTopic!) })) &&
            selectedDuration.includes(duration: $0.duration) &&
            (searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {

                // Header
                Text("Finde passende Materialien")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 36/255, green: 37/255, blue: 44/255))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 40)

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Suche nach Titel...")
                                .foregroundColor(.gray)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        TextField("", text: $searchText)
                            .foregroundColor(.black)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .autocorrectionDisabled(true)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                // Filters (collapsed/expanded)
                filterSection

                // Results
                Group {
                    if let err = errorText {
                        VStack(spacing: 8) {
                            Text("Fehler beim Laden").font(.headline)
                            Text(err).font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)
                            Button("Erneut versuchen") { Task { await loadMaterialsFromBackend() } }
                                .buttonStyle(CurvedBorderedButtonStyle())
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding(.top, 40)
                    } else if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Lade Materialien…").font(.footnote).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding(.top, 40)
                    } else if filteredMaterials.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray.opacity(0.4))
                            Text("Keine passenden Ergebnisse gefunden.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Show only the first 'visibleCount' materials
                                ForEach(Array(filteredMaterials.prefix(visibleCount).enumerated()), id: \.element.id) { index, material in
                                    NavigationLink(destination: MaterialDetailView(material: material)) {
                                        MaterialCardView(
                                            material: material,
                                            isFavorite: material.isFavorite,
                                            toggleFavorite: {
                                                if appState.isLoggedIn {
                                                    toggleFavorite(material)
                                                } else {
                                                    showingLoginAlert = true
                                                }
                                            }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                // "Load More" button if there are more materials
                                if filteredMaterials.count > visibleCount {
                                    Button("Weitere Materialien anzeigen (\(filteredMaterials.count - visibleCount))") {
                                        withAnimation(.easeInOut) {
                                            visibleCount = min(visibleCount + 10, filteredMaterials.count)
                                        }
                                    }
                                    .buttonStyle(PillBorderedButtonStyle())
                                    .padding(.top, 8)
                                }
                            }
                            .padding()
                        }
                        .refreshable { 
                            await loadMaterialsFromBackend()
                            visibleCount = 10 // Reset visible count on refresh
                        }
                    }
                }
                .alert("Bitte einloggen", isPresented: $showingLoginAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Du musst eingeloggt sein, um Favoriten zu speichern.")
                }
            }
        }
        .task { await loadMaterialsFromBackend() }
        .onChange(of: searchText) { visibleCount = 10 }
        .onChange(of: selectedGrade) { visibleCount = 10 }
        .onChange(of: selectedTopic) { visibleCount = 10 }
        .onChange(of: selectedDevice) { visibleCount = 10 }
        .onChange(of: selectedDuration) { visibleCount = 10 }
    }

    // MARK: - Filters (all inside the toggleable panel)

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Toggle button (subtle bordered style)
            Button(action: { withAnimation(.easeInOut) { showFilters.toggle() } }) {
                HStack {
                    Image(systemName: showFilters
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                        .foregroundColor(.secondary)
                    Text(showFilters ? "Filter ausblenden" : "Filter anzeigen")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    if filtersActiveCount > 0 {
                        Text("(\(filtersActiveCount))")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: showFilters ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .accessibilityLabel("Filter anzeigen oder ausblenden")

            // Summary line when collapsed
            if !showFilters {
                Text(filterSummaryText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }

            // Full filter panel
            if showFilters {
                VStack(alignment: .leading, spacing: 12) {

                    // Row 1: Klasse, Dauer
                    HStack(spacing: 12) {
                        FilterPicker(
                            title: "Klasse",
                            options: (1...4).map { "Klasse \($0)" },
                            selection: Binding(
                                get: { selectedGrade.map { "Klasse \($0)" } },
                                set: { selectedGrade = Int($0?.components(separatedBy: " ").last ?? "") }
                            ),
                            allLabel: "Alle Klassen"
                        )

                        FilterPicker(
                            title: "Dauer",
                            options: DurationFilter.allCases
                                .filter { $0 != .all } // “Alle Dauern” via allLabel
                                .map { $0.label },
                            selection: Binding(
                                get: { selectedDuration == .all ? nil : selectedDuration.label },
                                set: { newValue in
                                    if let label = newValue,
                                       let picked = DurationFilter.allCases.first(where: { $0.label == label }) {
                                        selectedDuration = picked
                                    } else {
                                        selectedDuration = .all
                                    }
                                }
                            ),
                            allLabel: "Alle Dauern"
                        )
                    }

                    // Row 2: Gerät, Thema (German labels)
                    HStack(spacing: 12) {
                        FilterPicker(
                            title: "Gerät",
                            options: Array(
                                Set(
                                    materials.flatMap { $0.devices }
                                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                        .filter { !$0.isEmpty }
                                )
                            ).sorted(),
                            selection: $selectedDevice,
                            allLabel: "Alle Geräte"
                        )

                        FilterPicker(
                            title: "Thema",
                            options: Array(
                                Set(
                                    materials.flatMap { $0.topics }
                                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                        .filter { !$0.isEmpty }
                                )
                            ).sorted(),
                            selection: $selectedTopic,
                            allLabel: "Alle Themen"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Data

    @MainActor
    private func loadMaterialsFromBackend() async {
        isLoading = true; errorText = nil
        defer { isLoading = false }

        do {
            let client = APIClient()
            let svc = LiveActivitiesAPI(api: client)
            
            if appState.isLoggedIn {
                // If logged in, try to fetch and mark favorites
            do {
                try await fetchAndMarkFavorites(svc: svc)
            } catch let error as APIError where error.status == 401 {
                await appState.refreshSession()
                try await fetchAndMarkFavorites(svc: svc)
                }
            } else {
                // If not logged in, just fetch materials without favorites
                let fetched = try await svc.listActivities()
                self.materials = fetched
            }
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }

    @MainActor
    private func fetchAndMarkFavorites(svc: LiveActivitiesAPI) async throws {
        // Fetch all activities
        let fetched = try await svc.listActivities()
        
        // Fetch favorite activities from backend
        let favorites = try await svc.getFavoriteActivities()
        let favIDs = Set(favorites.map { $0.id })
        
        // Mark favorites
        self.materials = fetched.map { m in
            var x = m; x.isFavorite = favIDs.contains(m.id); return x
        }
    }

    private func toggleFavorite(_ material: Material) {
        guard let idx = materials.firstIndex(where: { $0.id == material.id }) else { return }
        
        // Optimistically update UI
        let wasFavorite = materials[idx].isFavorite
        materials[idx].isFavorite.toggle()

        // Update backend
        Task {
            do {
                let client = APIClient()
                let svc = LiveActivitiesAPI(api: client)
                
        if materials[idx].isFavorite {
                    // Save favorite
                    _ = try await svc.saveFavoriteActivity(activityId: material.id, name: nil)
        } else {
                    // Remove favorite
                    _ = try await svc.removeFavoriteActivity(activityId: material.id)
                }
            } catch {
                // Revert on error
                await MainActor.run {
                    if let idx = materials.firstIndex(where: { $0.id == material.id }) {
                        materials[idx].isFavorite = wasFavorite
                    }
                }
                print("Error toggling favorite: \(error)")
            }
        }
    }
}

// MARK: - Helpers

private extension String {
    func equalsCaseInsensitive(_ other: String) -> Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveCompare(
                other.trimmingCharacters(in: .whitespacesAndNewlines)
            ) == .orderedSame
    }
}
