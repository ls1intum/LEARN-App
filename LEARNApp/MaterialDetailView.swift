//
//  MaterialDetailView.swift
//  Master
//
//  Created by Minkyoung Park on 13.10.25.
//

import SwiftUI

private func bloomDeutsch(_ raw: String?) -> String {
    guard let r = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !r.isEmpty else { return "—" }
    switch r {
    case "remember":   return "Erinnern"
    case "understand": return "Verstehen"
    case "apply":      return "Anwenden"
    case "analyze":    return "Analysieren"
    case "evaluate":   return "Bewerten"
    case "create":     return "Erschaffen"
    default:           return r.capitalized
    }
}

struct MaterialDetailView: View {
    let material: Material
    @Environment(\.dismiss) private var dismiss

    private var devicesJoined: String {
        let list = material.devices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return list.isEmpty ? "—" : list.joined(separator: ", ")
    }

    private var topicsJoined: String {
        let list = material.topics.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return list.isEmpty ? "—" : list.joined(separator: ", ")
    }

    private var ageRangeText: String {
        switch (material.ageMin, material.ageMax) {
        case let (min?, max?) where max >= min: return "\(min)–\(max) Jahre"
        case let (min?, nil): return "ab \(min) Jahren"
        case let (nil, max?): return "bis \(max) Jahre"
        default: return "—"
        }
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

    private func plainText(_ v: Int?) -> String {
        guard let v else { return "—" }
        return String(v)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(material.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Category
                Label("Kategorie: \(material.category)", systemImage: "folder")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)

                Divider()

                // Main information
                VStack(alignment: .leading, spacing: 8) {
                    Label(gradeRangeText(material), systemImage: "person.2")
                    Label("Dauer: \(durationText)", systemImage: "clock")
                    Label("Vorbereitungszeit: \(minutesText(material.prepTimeMinutes))", systemImage: "wrench.and.screwdriver")
                    Label("Aufräumzeit: \(minutesText(material.cleanupTimeMinutes))", systemImage: "trash")
                    Label("Mentale Beanspruchung: \(material.mentalLoad?.label ?? "—")", systemImage: "brain.head.profile")
                    Label("Körperliche Aktivität: \(material.physicalEnergy?.label ?? "—")", systemImage: "figure.walk")
                    Label("Bloom-Stufe: \(bloomDeutsch(material.bloomLevel))", systemImage: "chart.bar.fill")
                }
                .font(.system(size: 15))
                .foregroundColor(AppColors.textMuted)

                Divider()

                // Devices & Topics
                VStack(alignment: .leading, spacing: 8) {
                    Label("Geräte: \(devicesJoined)", systemImage: "desktopcomputer")
                    Label("Themen: \(topicsJoined)", systemImage: "book.closed")
                }
                .font(.system(size: 15))
                .foregroundColor(AppColors.textMuted)

                Divider()

                // Quelle
                VStack(alignment: .leading, spacing: 8) {
                    Label("Quelle: \(material.source?.isEmpty == false ? material.source! : "—")", systemImage: "link")
                }
                .font(.system(size: 15))
                .foregroundColor(AppColors.textMuted)

                Spacer()
            }
            .padding(20)
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
    }
}
