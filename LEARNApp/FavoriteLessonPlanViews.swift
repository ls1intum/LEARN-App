//
//  FavoriteLessonPlanViews.swift
//  Master
//
//  Created by Minkyoung Park on 15.10.25.
//

import SwiftUI

struct FavoriteLessonPlanCardView: View {
    let lessonPlan: FavoriteLessonPlan
    let toggleFavorite: () -> Void
    
    private var gradeRangeText: String {
        guard !lessonPlan.activities.isEmpty else { return "—" }
        
        let grades = lessonPlan.activities.compactMap { activity -> [Int] in
            if let min = activity.gradeMin, let max = activity.gradeMax {
                return [min, max]
            } else {
                return [activity.grade]
            }
        }.flatMap { $0 }
        
        guard let minGrade = grades.min(), let maxGrade = grades.max() else {
            return "—"
        }
        
        if minGrade == maxGrade {
            return "Klasse \(minGrade)"
        } else {
            return "Klasse \(minGrade)–\(maxGrade)"
        }
    }
    
    private var durationRangeText: String {
        let minDuration = lessonPlan.activities.reduce(0) { $0 + $1.duration }
        let maxDuration = lessonPlan.activities.reduce(0) { sum, activity in
            sum + (activity.durationMax ?? activity.duration)
        }
        
        if minDuration == maxDuration {
            return "Dauer: \(minDuration) Min"
        } else {
            return "Dauer: \(minDuration)–\(maxDuration) Min"
        }
    }
    
    private var activityCountText: String {
        let count = lessonPlan.activities.count
        if count == 1 {
            return "Besteht aus 1 Aktivität"
        } else {
            return "Besteht aus \(count) Aktivitäten"
        }
    }
    
    private var createdAtText: String {
        guard let date = lessonPlan.createdAt else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")
        return "Erstellt am \(formatter.string(from: date))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and heart button
            HStack {
                Text(lessonPlan.name ?? "Gespeicherte Idee")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.title)
                Spacer()
                Button(action: toggleFavorite) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(AppColors.primaryDark)
                }
                .buttonStyle(.plain)
            }
            
            // Meta information
            VStack(alignment: .leading, spacing: 6) {
                Label(gradeRangeText, systemImage: "person.2")
                Label(durationRangeText, systemImage: "clock")
                Label(activityCountText, systemImage: "list.bullet")
                Label(createdAtText, systemImage: "calendar")
            }
            .font(.system(size: 12))
            .foregroundColor(AppColors.textMuted)
        }
        .padding()
        .background(AppColors.cardBG)
        .cornerRadius(12)
    }
}

struct FavoriteLessonPlanDetailView: View {
    let lessonPlan: FavoriteLessonPlan
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(lessonPlan.name ?? "Gespeicherte Idee")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.title)
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("\(lessonPlan.totalDuration) Minuten")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "list.bullet")
                            .foregroundColor(.secondary)
                        Text("\(lessonPlan.activities.count) Aktivitäten")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(AppColors.cardBG)
                .cornerRadius(12)
                
                // Activities
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lessonPlan.activities.enumerated()), id: \.element.id) { index, material in
                        if index > 0 { Divider() }
                        FavoriteInlineMaterialView(material: material)
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
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FavoriteInlineMaterialView: View {
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
