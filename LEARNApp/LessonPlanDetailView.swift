//
//  LessonPlanDetailView.swift
//  Master
//
//  Created by Minkyoung Park on 13.10.25.
//

import SwiftUI

struct LessonPlanDetailView: View {
    let recommendation: Recommendation  // activities: [Material], score: Double?
    let recommendationIndex: Int
    @Binding var showProgressBar: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var isFavorite = false
    @State private var isSavingFavorite = false
    @State private var showingLoginAlert = false
    @State private var currentFavouriteId: Int? = nil  // Track the favorite ID for deletion
    @State private var showingNameDialog = false
    @State private var lessonPlanName = ""
    @State private var isGeneratingPDF = false
    @State private var showingPDFError = false
    @State private var pdfErrorText = ""

    private var totalMinMinutes: Int {
        recommendation.activities.reduce(0) { $0 + max(0, $1.duration) }
    }

    private var totalMaxMinutes: Int {
        let sumMax = recommendation.activities.reduce(0) { partial, m in
            partial + (m.durationMax ?? m.duration)
        }
        return max(sumMax, totalMinMinutes)
    }

    private var totalDurationText: String {
        if totalMaxMinutes > totalMinMinutes {
            return "\(totalMinMinutes)–\(totalMaxMinutes) Minuten"
        } else {
            return "\(totalMinMinutes) Minuten"
        }
    }

    private var classRangeText: String {
        let mins = recommendation.activities.compactMap { $0.gradeMin ?? $0.grade }
        let maxs = recommendation.activities.compactMap { $0.gradeMax ?? $0.grade }
        guard let gMin = mins.min(), let gMax = maxs.max() else {
            return "—"
        }
        return gMin == gMax ? "Klasse \(gMin)" : "Klassenstufen \(gMin) – \(gMax)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Deine Unterrichtsidee")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.title)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "clock")
                                .frame(width: 20, alignment: .leading)
                            Text("Gesamtdauer: \(totalDurationText)")
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "person.2")
                                .frame(width: 20, alignment: .leading)
                            Text(classRangeText)
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                }
                .padding(16)
                .background(AppColors.cardBG)
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(recommendation.activities.enumerated()), id: \.element.id) { index, material in
                        if index > 0 { Divider() }
                        InlineMaterialView(material: material)
                            .padding(16)
                    }
                }
                .background(AppColors.cardBG)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15)))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
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
            ToolbarItem(placement: .principal) {
                Text("Idee \(recommendationIndex)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? AppColors.primaryDark : .gray)
                        .font(.system(size: 18))
                }
                .disabled(isSavingFavorite)
                .buttonStyle(.plain)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button {
                    Task { await generateAndDownloadPDF() }
                } label: {
                    HStack(spacing: 8) {
                        if isGeneratingPDF {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "doc.text")
                        }
                        Text(isGeneratingPDF ? "PDF wird erstellt..." : "Als PDF herunterladen")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CurvedFilledButtonStyle())
                .disabled(isGeneratingPDF)
            }
            .padding(16)
            .background(Color.clear)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            showProgressBar = false
            Task { await checkIfFavorited() }
        }
        .alert("Bitte einloggen", isPresented: $showingLoginAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Du musst eingeloggt sein, um Lehrpläne zu speichern.")
        }
        .alert("Unterrichtsidee benennen", isPresented: $showingNameDialog) {
            TextField("Name (optional)", text: $lessonPlanName)
            Button("Speichern") {
                Task { await saveFavoriteLessonPlan() }
            }
            Button("Abbrechen", role: .cancel) {
                lessonPlanName = ""
            }
        } message: {
            Text("Gib deiner Unterrichtsidee einen Namen, um sie leichter wiederzufinden.")
        }
        .alert("PDF-Fehler", isPresented: $showingPDFError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pdfErrorText)
        }
    }
    
    private func toggleFavorite() {
        guard appState.isLoggedIn else {
            showingLoginAlert = true
            return
        }
        
        if isFavorite {
            // Remove favorite
            Task { await removeFavoriteLessonPlan() }
        } else {
            // Show naming dialog before saving
            lessonPlanName = "Idee \(recommendationIndex)"
            showingNameDialog = true
        }
    }
    
    @MainActor
    private func saveFavoriteLessonPlan() async {
        isSavingFavorite = true
        defer { isSavingFavorite = false }
        
        do {
            let client = APIClient()
            let api = LiveActivitiesAPI(api: client)
            
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
            
            // Save the favourite ID for later deletion
            if let id = favouriteId {
                currentFavouriteId = id
                isFavorite = true
            } else {
                isFavorite = true
            }
            
        } catch {
            print("Error saving favorite lesson plan: \(error)")
        }
    }
    
    @MainActor
    private func removeFavoriteLessonPlan() async {
        guard let favouriteId = currentFavouriteId else { return }
        
        isSavingFavorite = true
        defer { isSavingFavorite = false }
        
        do {
            let client = APIClient()
            let api = LiveActivitiesAPI(api: client)
            
            let _ = try await api.deleteFavoriteLessonPlan(favouriteId: favouriteId)
            isFavorite = false
            currentFavouriteId = nil
            
        } catch {
            print("Error removing favorite lesson plan: \(error)")
        }
    }
    
    @MainActor
    private func checkIfFavorited() async {
        guard appState.isLoggedIn else { return }
        
        do {
            let client = APIClient()
            let api = LiveActivitiesAPI(api: client)
            
            // Get all favorite lesson plans
            let favoritePlans = try await api.getFavoriteLessonPlans()
            
            // Get the current recommendation's activity IDs
            let currentActivityIds = Set(recommendation.activities.map { $0.id })
            
            // Check if any favorite matches this lesson plan
            if let matchingFavorite = favoritePlans.first(where: { plan in
                let planActivityIds = Set(plan.activities.map { $0.id })
                return planActivityIds == currentActivityIds
            }) {
                isFavorite = true
                currentFavouriteId = matchingFavorite.id
            }
            
        } catch {
            print("Error checking favorite status: \(error)")
        }
    }
    
    @MainActor
    private func generateAndDownloadPDF() async {
        isGeneratingPDF = true
        defer { isGeneratingPDF = false }
        
        do {
            let client = APIClient()
            let api = LiveActivitiesAPI(api: client)
            
            // Build search criteria
            let topicsSet = Set(recommendation.activities.flatMap { $0.topics })
            let devicesSet = Set(recommendation.activities.flatMap { $0.devices })
            let searchCriteria: [String: String] = [
                "duration": "\(totalMinMinutes)",
                "topics": Array(topicsSet).joined(separator: ","),
                "devices": Array(devicesSet).joined(separator: ",")
            ]
            
            let request = LessonPlanPDFRequest(
                activities: recommendation.activities.map { $0.toActivityForPDF() },
                searchCriteria: searchCriteria,
                name: "Idee \(recommendationIndex)"
            )
            
            let pdfData = try await api.generateLessonPlanPDF(request)
            
            // Save PDF to documents directory
            await savePDFToDocuments(pdfData: pdfData, filename: "Unterrichtsidee_\(recommendationIndex).pdf")
            
        } catch {
            pdfErrorText = (error as? LocalizedError)?.errorDescription ?? "Fehler beim Erstellen der PDF: \(error.localizedDescription)"
            showingPDFError = true
        }
    }
    
    @MainActor
    private func savePDFToDocuments(pdfData: Data, filename: String) async {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(filename)
            
            try pdfData.write(to: fileURL)
            
            // Present share sheet
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
            
        } catch {
            pdfErrorText = "Fehler beim Speichern der PDF: \(error.localizedDescription)"
            showingPDFError = true
        }
    }
}

private struct InlineMaterialView: View {
    let material: Material

    private var devicesJoined: String {
        let list = material.devices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return list.isEmpty ? "—" : list.joined(separator: ", ")
    }

    private var topicsJoined: String {
        let list = material.topics.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return list.isEmpty ? "—" : list.joined(separator: ", ")
    }

    private var durationText: String {
        if let max = material.durationMax, max >= material.duration {
            return "\(material.duration)–\(max) Minuten"
        } else {
            return "\(material.duration) Minuten"
        }
    }

    private func minutesText(_ v: Int?) -> String {
        guard let v, v > 0 else { return "—" }
        return "\(v) Minuten"
    }

    private func gradeRangeText(_ m: Material) -> String {
        switch (m.gradeMin, m.gradeMax) {
        case let (min?, max?) where min == max:
            return "Klassenstufe: \(min)"
        case let (min?, max?):
            return "Klassenstufen: \(min) – \(max)"
        case (nil, nil):
            return "Klassenstufe: \(m.grade)"
        case let (min?, nil):
            return "Klassenstufe: \(min)"
        case let (nil, max?):
            return "Klassenstufe: \(max)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(material.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.title)
                .frame(maxWidth: .infinity, alignment: .leading)

            Label("Kategorie: \(material.category)", systemImage: "folder")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label(gradeRangeText(material), systemImage: "person.2")
                Label("Dauer: \(durationText)", systemImage: "clock")
                Label("Vorbereitungszeit: \(minutesText(material.prepTimeMinutes))", systemImage: "wrench.and.screwdriver")
                Label("Aufräumzeit: \(minutesText(material.cleanupTimeMinutes))", systemImage: "trash")
                Label("Mentale Beanspruchung: \(material.mentalLoad?.label ?? "—")", systemImage: "brain.head.profile")
                Label("Körperliche Aktivität: \(material.physicalEnergy?.label ?? "—")", systemImage: "figure.walk")
                Label("Bloom-Stufe: \(material.bloomLevel ?? "—")", systemImage: "chart.bar.fill")
            }
            .font(.system(size: 14))
            .foregroundColor(AppColors.textMuted)

            VStack(alignment: .leading, spacing: 8) {
                Label("Geräte: \(devicesJoined)", systemImage: "desktopcomputer")
                Label("Themen: \(topicsJoined)", systemImage: "book.closed")
            }
            .font(.system(size: 14))
            .foregroundColor(AppColors.textMuted)
        }
    }
}
