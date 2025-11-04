//
//  PlanStep.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI

// Lightweight route for navigation (no need for models to be Hashable)
private enum PlanRoute: Hashable {
    case material(id: Int)
    case plan(index: Int)   // index in current recs array
}

struct PlanStepView: View {
    let selectedGrade: Int?                // 1...4
    let selectedDurationMinutes: Int       // minutes
    let selectedDevices: Set<Device>       // from DevicesStepView
    let selectedTopics: Set<Topic>
    let onRestart: () -> Void
    let onBack: () -> Void
    @Binding var showProgressBar: Bool
    let useNavigationStack: Bool           // Whether to wrap in NavigationStack

    @EnvironmentObject var appState: AppState

    @State private var recs: [Recommendation] = []
    @State private var isLoading = false
    @State private var errorText: String?

    @State private var visibleCount: Int = 3
    
    @State private var navPath = NavigationPath()
    
    // Favorite state tracking
    @State private var favoriteIds: Set<Int> = []  // Track favorite IDs by recommendation index
    @State private var favouriteRecordIds: [Int: Int] = [:]  // Map recommendation index to backend favourite_id
    @State private var showingNameDialog = false
    @State private var showingLoginAlert = false
    @State private var lessonPlanName = ""
    @State private var pendingFavoriteIndex: Int? = nil
    @State private var pendingFavoriteRec: Recommendation? = nil
    
    init(selectedGrade: Int?, selectedDurationMinutes: Int, selectedDevices: Set<Device>, selectedTopics: Set<Topic>, onRestart: @escaping () -> Void, onBack: @escaping () -> Void, showProgressBar: Binding<Bool>, useNavigationStack: Bool = true) {
        self.selectedGrade = selectedGrade
        self.selectedDurationMinutes = selectedDurationMinutes
        self.selectedDevices = selectedDevices
        self.selectedTopics = selectedTopics
        self.onRestart = onRestart
        self.onBack = onBack
        self._showProgressBar = showProgressBar
        self.useNavigationStack = useNavigationStack
    }

    var body: some View {
        let content = VStack(spacing: 16) {
            header
            if useNavigationStack {
                contentList
            } else {
                contentListWithDirectNavigation
            }
        }
        .padding(.horizontal, 16)
        .navigationTitle("Empfehlungen")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    onBack()
                }) {
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
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Neu") {
                    onRestart()
                }
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            showProgressBar = false
            Task {
                await checkFavoriteStatus()
            }
        }
        .task {
            await fetchRecommendations()
            await checkFavoriteStatus()
        }
        .navigationDestination(for: PlanRoute.self) { route in
            destination(for: route)
        }
        .alert("Unterrichtsidee benennen", isPresented: $showingNameDialog) {
            TextField("Name (optional)", text: $lessonPlanName)
            Button("Speichern") {
                if let index = pendingFavoriteIndex, let rec = pendingFavoriteRec {
                    Task { await saveLessonPlanFavorite(index: index, recommendation: rec) }
                }
            }
            Button("Abbrechen", role: .cancel) {
                lessonPlanName = ""
                pendingFavoriteIndex = nil
                pendingFavoriteRec = nil
            }
        } message: {
            Text("Gib deiner Unterrichtsidee einen Namen, um sie leichter wiederzufinden.")
        }
        .alert("Bitte einloggen", isPresented: $showingLoginAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Um Favoriten zu speichern, musst du eingeloggt sein.")
        }
        
        if useNavigationStack {
            NavigationStack(path: $navPath) {
                content
            }
        } else {
            content
        }
    }
}

// MARK: - Subviews

private extension PlanStepView {

    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Passende Aktivitäten für dich")
                .font(.system(size: 22, weight: .bold))
            Text("Perfekt zugeschnitten auf deine Angaben.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    @ViewBuilder
    var contentList: some View {
        if isLoading {
            loadingView
        } else if let err = errorText {
            errorView(err)
        } else if recs.isEmpty {
            emptyView
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(recs.prefix(visibleCount).enumerated()), id: \.offset) { idx, rec in
                        recommendationRow(index: idx, rec: rec)
                    }

                    if recs.count > visibleCount {
                        let remaining = recs.count - visibleCount
                        let toShow = min(5, remaining)
                        Button("Weitere Vorschläge anzeigen (\(toShow))") {
                            withAnimation(.easeInOut) {
                                visibleCount = min(visibleCount + 5, recs.count)
                            }
                        }
                        .buttonStyle(PillBorderedButtonStyle())
                        .padding(.top, 6)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    @ViewBuilder
    var contentListWithDirectNavigation: some View {
        if isLoading {
            loadingView
        } else if let err = errorText {
            errorView(err)
        } else if recs.isEmpty {
            emptyView
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(recs.prefix(visibleCount).enumerated()), id: \.offset) { idx, rec in
                        NavigationLink(destination: LessonPlanDetailView(
                            recommendation: rec,
                            recommendationIndex: idx + 1,
                            showProgressBar: $showProgressBar
                        )) {
                            recommendationRowContent(index: idx, rec: rec)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if recs.count > visibleCount {
                        let remaining = recs.count - visibleCount
                        let toShow = min(5, remaining)
                        Button("Weitere Vorschläge anzeigen (\(toShow))") {
                            withAnimation(.easeInOut) {
                                visibleCount = min(visibleCount + 5, recs.count)
                            }
                        }
                        .buttonStyle(PillBorderedButtonStyle())
                        .padding(.top, 6)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Erzeuge Empfehlungen…")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    func errorView(_ err: String) -> some View {
        VStack(spacing: 8) {
            Text("Fehler: \(err)")
                .foregroundColor(.red)
                .font(.footnote)
            Button("Erneut versuchen") { Task { await fetchRecommendations() } }
                .buttonStyle(CurvedBorderedButtonStyle())
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    var emptyView: some View {
        Text("Keine Empfehlungen gefunden.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 160)
    }

    func recommendationRow(index idx: Int, rec: Recommendation) -> some View {
        let route: PlanRoute = {
            if rec.activities.count == 1, let mat = rec.activities.first {
                return .material(id: mat.id)
            } else {
                return .plan(index: idx)
            }
        }()

        return NavigationLink(value: route) {
            recommendationRowContent(index: idx, rec: rec)
        }
        .buttonStyle(.plain)
    }
    
    func recommendationRowContent(index idx: Int, rec: Recommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Idee \(idx + 1)")
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: {
                    toggleLessonPlanFavorite(index: idx, recommendation: rec)
                }) {
                    Image(systemName: favoriteIds.contains(idx) ? "heart.fill" : "heart")
                        .foregroundColor(favoriteIds.contains(idx) ? AppColors.primaryDark : .gray)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }

            ForEach(rec.activities) { material in
                MaterialCardView(
                    material: material,
                    isFavorite: material.isFavorite,
                    toggleFavorite: { /* no-op inside tappable card */ },
                    showFavoriteButton: false
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
        .contentShape(Rectangle())
    }

    // Resolve routes to actual destinations
    @ViewBuilder
    func destination(for route: PlanRoute) -> some View {
        switch route {
        case .material(let id):
            if let mat = findMaterial(by: id) {
                MaterialDetailView(material: mat)
            } else {
                Text("Material nicht gefunden").foregroundColor(.secondary)
            }
        case .plan(let index):
            if recs.indices.contains(index) {
                LessonPlanDetailView(recommendation: recs[index], recommendationIndex: index + 1, showProgressBar: $showProgressBar)
            } else {
                Text("Plan nicht gefunden").foregroundColor(.secondary)
            }
        }
    }

    // Helper: find a material in the current recommendations
    func findMaterial(by id: Int) -> Material? {
        for r in recs {
            if let m = r.activities.first(where: { $0.id == id }) { return m }
        }
        return nil
    }
    
    func toggleLessonPlanFavorite(index: Int, recommendation: Recommendation) {
        guard appState.isLoggedIn else {
            showingLoginAlert = true
            return
        }
        
        if favoriteIds.contains(index) {
            // Remove favorite
            Task { await removeLessonPlanFavorite(index: index) }
        } else {
            // Show naming dialog before saving
            lessonPlanName = "Idee \(index + 1)"  // Pre-fill with default
            pendingFavoriteIndex = index
            pendingFavoriteRec = recommendation
            showingNameDialog = true
        }
    }
}

// MARK: - Networking

private extension PlanStepView {
    
    @MainActor
    func saveLessonPlanFavorite(index: Int, recommendation: Recommendation) async {
        do {
            let client = APIClient()
            let api = LiveActivitiesAPI(api: client)
            
            let totalMinMinutes = recommendation.activities.reduce(0) { $0 + max(0, $1.duration) }
            
            let finalName = lessonPlanName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Build search criteria
            let topicsSet = Set(recommendation.activities.flatMap { $0.topics })
            let devicesSet = Set(recommendation.activities.flatMap { $0.devices })
            let searchCriteria: [String: String] = [
                "duration": "\(totalMinMinutes)",
                "topics": Array(topicsSet).joined(separator: ","),
                "devices": Array(devicesSet).joined(separator: ",")
            ]
            
            let request = FavoriteLessonPlanRequest(
                activityIds: recommendation.activities.map { $0.id },
                lessonPlan: LessonPlanMetadata(
                    name: nil,
                    searchCriteria: searchCriteria,
                    totalDuration: totalMinMinutes
                ),
                name: finalName.isEmpty ? nil : finalName
            )
            
            let favouriteId = try await api.saveFavoriteLessonPlan(request, fullActivities: recommendation.activities)
            
            favoriteIds.insert(index)
            if let id = favouriteId {
                favouriteRecordIds[index] = id
            }
            
            // Clean up
            lessonPlanName = ""
            pendingFavoriteIndex = nil
            pendingFavoriteRec = nil
            
        } catch {
            print("Error saving lesson plan favorite: \(error)")
            // Clean up on error too
            lessonPlanName = ""
            pendingFavoriteIndex = nil
            pendingFavoriteRec = nil
        }
    }
    
    @MainActor
    func removeLessonPlanFavorite(index: Int) async {
        guard let favouriteId = favouriteRecordIds[index] else {
            favoriteIds.remove(index)
            return
        }
        
        do {
            let client = APIClient()
            let api = LiveActivitiesAPI(api: client)
            
            let _ = try await api.deleteFavoriteLessonPlan(favouriteId: favouriteId)
            
            favoriteIds.remove(index)
            favouriteRecordIds.removeValue(forKey: index)
            
        } catch {
            print("Error removing lesson plan favorite: \(error)")
        }
    }
    
    @MainActor
    func checkFavoriteStatus() async {
        guard appState.isLoggedIn else { return }
        guard !recs.isEmpty else { return }
        
        do {
            let client = APIClient()
            let api = LiveActivitiesAPI(api: client)
            
            // Get all favorite lesson plans
            let favoritePlans = try await api.getFavoriteLessonPlans()
            
            // Clear existing state to sync with backend
            var newFavoriteIds: Set<Int> = []
            var newFavouriteRecordIds: [Int: Int] = [:]
            
            // Check each recommendation against favorites
            for (index, rec) in recs.enumerated() {
                let currentActivityIds = Set(rec.activities.map { $0.id })
                
                if let matchingFavorite = favoritePlans.first(where: { plan in
                    let planActivityIds = Set(plan.activities.map { $0.id })
                    return planActivityIds == currentActivityIds
                }) {
                    newFavoriteIds.insert(index)
                    newFavouriteRecordIds[index] = matchingFavorite.id
                }
            }
            
            // Update state with new values
            favoriteIds = newFavoriteIds
            favouriteRecordIds = newFavouriteRecordIds
            
        } catch {
            print("Error checking favorite status: \(error)")
        }
    }
    
    @MainActor
    func fetchRecommendations() async {
        isLoading = true; errorText = nil
        defer { isLoading = false }

        do {
            let client = APIClient()
            let api = LiveActivitiesAPI(api: client)

            // Build query from selections
            let age = selectedGrade.map { $0 + 5 }                    // 1->6 ... 4->9
            let durationMinutes = max(1, min(480, selectedDurationMinutes))

            let resources = selectedDevices
                .map(\.rawValue)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .sorted()
            let resourcesParam = resources.isEmpty ? nil : resources

            let topics = Array(selectedTopics.map(\.rawValue))
            let topicsParam: [String]? = topics.isEmpty ? nil : topics

            do {
                recs = try await api.getRecommendations(
                    name: nil,
                    targetAge: age,
                    format: nil,
                    bloomLevels: nil,
                    targetDuration: durationMinutes,
                    availableResources: resourcesParam,
                    preferredTopics: topicsParam,
                    priorityCategories: topicsParam,
                    includeBreaks: false,
                    limit: 10,
                    maxActivityCount: 2
                )
            } catch let error as APIError where error.status == 401 {
                await appState.refreshSession()
                recs = try await api.getRecommendations(
                    name: nil,
                    targetAge: age,
                    format: nil,
                    bloomLevels: nil,
                    targetDuration: durationMinutes,
                    availableResources: resourcesParam,
                    preferredTopics: nil,
                    priorityCategories: topicsParam,
                    includeBreaks: false,
                    limit: 10,
                    maxActivityCount: 2
                )
            }

            // Mark favorites
            let favIDs = Set(FavoritesStore.load(for: appState.userEmail))
            recs = recs.map { r in
                let mats = r.activities.map { m -> Material in
                    var mm = m; mm.isFavorite = favIDs.contains(m.id); return mm
                }
                return Recommendation(activities: mats, score: r.score)
            }

            visibleCount = min(3, recs.count)

        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }
}
