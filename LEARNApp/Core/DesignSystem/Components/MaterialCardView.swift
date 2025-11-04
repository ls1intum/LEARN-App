//
//  MaterialCardView.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import SwiftUI

struct MaterialCardView: View {
    let material: Material
    let isFavorite: Bool
    let toggleFavorite: () -> Void
    var showDevicePill: Bool = true   // optional toggles
    var showMetaList: Bool = true
    var showFavoriteButton: Bool = true
    
    private var devicesJoined: String {
        let list = material.devices
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return list.isEmpty ? "—" : list.joined(separator: ", ")
    }

    private var leadingDevicePills: [String] {
        Array(material.devices
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3))
    }

    private var remainingDeviceCount: Int {
        max(0, material.devices
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count - 3)
    }
    
    private var durationText: String {
        if let max = material.durationMax, max > material.duration {
            return "\(material.duration)–\(max) Min"
        } else {
            return "\(material.duration) Min"
        }
    }
    
    private var topicsJoined: String {
        let list = material.topics
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return list.isEmpty ? "—" : list.joined(separator: ", ")
    }
    
    private func gradeRangeText(_ m: Material) -> String {
        switch (m.gradeMin, m.gradeMax) {
        case let (min?, max?) where min == max:
            return "Klasse \(min)"
        case let (min?, max?):
            return "Klasse \(min) – \(max)"
        case (nil, nil):
            return "Klasse \(m.grade)" // Fallback
        case let (min?, nil):
            return "Klasse \(min)"
        case let (nil, max?):
            return "Klasse \(max)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showDevicePill {
                HStack(spacing: 6) {
                    ForEach(leadingDevicePills, id: \.self) { dev in
                        Text(dev.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.primaryDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.tagBG)
                            .cornerRadius(6)
                    }
                    if remainingDeviceCount > 0 {
                        Text("+\(remainingDeviceCount) weitere")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.primaryDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.tagBG)
                            .cornerRadius(6)
                    }
                    Spacer(minLength: 0)
                }
            }

            HStack {
                Text(material.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.title)
                Spacer()
                if showFavoriteButton {
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? AppColors.primaryDark : .gray)
                    }
                    .buttonStyle(.plain)
                }
            }

            if showMetaList {
                VStack(alignment: .leading, spacing: 8) {
                    Label(gradeRangeText(material), systemImage: "person")
                    Label("Dauer: \(durationText)", systemImage: "clock")
                    Label("Themen: \(topicsJoined)", systemImage: "book.closed")
                }
                .font(.system(size: 12))
                .foregroundColor(AppColors.textMuted)
            } else {
                Text("\(gradeRangeText(material)) • \(durationText) • Themen: \(topicsJoined)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .padding()
        .background(AppColors.cardBG)
        .cornerRadius(12)
    }
}

