//
//  FavoritesView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI

enum FavoriteTab: String, CaseIterable {
    case activities = "Aktivitäten"
    case lessonPlans = "Sets"
    
    var id: String { self.rawValue }
}

struct FavoritesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let showBackButton: Bool

    @State private var favoriteMaterials: [Material] = []
    @State private var favoriteLessonPlans: [FavoriteLessonPlan] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var selectedTab: FavoriteTab = .activities
    
    init(showBackButton: Bool = true) {
        self.showBackButton = showBackButton
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Favoriten")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 36/255, green: 37/255, blue: 44/255))
                .padding(.top, 40)
                .padding(.horizontal, 20)

            if appState.isLoggedIn {
                // Tab selector
                HStack(spacing: 0) {
                    ForEach(FavoriteTab.allCases, id: \.id) { tab in
                        Button(action: { selectedTab = tab }) {
                            VStack(spacing: 8) {
                                Text(tab.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(selectedTab == tab ? .primary : .secondary)
                                
                                Rectangle()
                                    .fill(selectedTab == tab ? Color.blue : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                content
            } else {
                LoggedOutView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(showBackButton)
        .toolbar {
            if showBackButton {
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
        .task { await loadFavorites() }                 // fetch on appear
        .onChange(of: appState.userEmail) {
            Task { await loadFavorites() }
        }
        .onChange(of: appState.isLoggedIn) { oldValue, newValue in
            if newValue { Task { await loadFavorites() } }
            else { favoriteMaterials = [] }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let err = errorText {
            VStack(spacing: 8) {
                Spacer()
                Text("Fehler beim Laden").font(.headline)
                Text(err).font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)
                Button("Erneut versuchen") { Task { await loadFavorites() } }
                    .buttonStyle(CurvedBorderedButtonStyle())
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isLoading {
            VStack(spacing: 12) {
                Spacer()
                ProgressView()
                Text("Lade Favoriten…").font(.footnote).foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch selectedTab {
            case .activities:
                activitiesContent
            case .lessonPlans:
                lessonPlansContent
            }
        }
    }
    
    @ViewBuilder
    private var activitiesContent: some View {
        if favoriteMaterials.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "heart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 138/255, green: 180/255, blue: 248/255))
                Text("Du hast noch keine\nAktivitäten als Favoriten gespeichert.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(favoriteMaterials, id: \.id) { material in
                        NavigationLink(destination: MaterialDetailView(material: material)) {
                            MaterialCardView(
                                material: material,
                                isFavorite: true,
                                toggleFavorite: { toggleFavorite(material) }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .refreshable { await loadFavorites() }
        }
    }
    
    @ViewBuilder
    private var lessonPlansContent: some View {
        if favoriteLessonPlans.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "heart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 138/255, green: 180/255, blue: 248/255))
                Text("Du hast noch keine\nLehrpläne als Favoriten gespeichert.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(favoriteLessonPlans, id: \.id) { lessonPlan in
                        NavigationLink(destination: FavoriteLessonPlanDetailView(lessonPlan: lessonPlan)) {
                            FavoriteLessonPlanCardView(
                                lessonPlan: lessonPlan,
                                toggleFavorite: { toggleLessonPlanFavorite(lessonPlan) }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .refreshable { await loadFavorites() }
        }
    }

    // MARK: - Data

    @MainActor
    private func loadFavorites() async {
        guard appState.isLoggedIn else { return }
        isLoading = true; errorText = nil
        defer { isLoading = false }

        do {
            let client = APIClient()
            let svc = LiveActivitiesAPI(api: client)
            
            // Load favorite activities from backend
            favoriteMaterials = try await svc.getFavoriteActivities()
                .map { var m = $0; m.isFavorite = true; return m }
            
            // Load favorite lesson plans from backend
            favoriteLessonPlans = try await svc.getFavoriteLessonPlans()
            
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }

    private func toggleFavorite(_ material: Material) {
        if let index = favoriteMaterials.firstIndex(of: material) {
            favoriteMaterials.remove(at: index)
        }
        
        // Remove from backend
        Task {
            do {
                let client = APIClient()
                let svc = LiveActivitiesAPI(api: client)
                _ = try await svc.removeFavoriteActivity(activityId: material.id)
            } catch {
                // Re-add on error
                await MainActor.run {
                    var m = material
                    m.isFavorite = true
                    favoriteMaterials.append(m)
                }
                print("Error removing favorite: \(error)")
            }
        }
    }
    
    private func toggleLessonPlanFavorite(_ lessonPlan: FavoriteLessonPlan) {
        if let index = favoriteLessonPlans.firstIndex(where: { $0.id == lessonPlan.id }) {
            favoriteLessonPlans.remove(at: index)
        }
        
        // Remove from backend
        Task {
            do {
                let client = APIClient()
                let svc = LiveActivitiesAPI(api: client)
                _ = try await svc.deleteFavoriteLessonPlan(favouriteId: lessonPlan.id)
            } catch {
                // Re-add on error
                await MainActor.run {
                    favoriteLessonPlans.append(lessonPlan)
                }
                print("Error removing lesson plan favorite: \(error)")
            }
        }
    }
}
