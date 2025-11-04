//
//  ActivityMapper.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import Foundation

extension ActivityDTO {
    func toMaterial(isFavorite: Bool = false) -> Material {

        // Map age → grade (6→1, 7→2, 8→3, 9→4), clamp to 1…4
        func gradeFromAge(_ age: Int?) -> Int? {
            guard let a = age else { return nil }
            return max(1, min(4, a - 5))
        }
        
        func mapLevel(_ s: LossyString?) -> EffortLevel? {
            guard let raw = s?.value?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
            let v = raw.lowercased()
            switch v {
            case "low", "niedrig", "1":   return .low
            case "medium", "mittel", "2": return .medium
            case "high", "hoch", "3":     return .high
            default:                      return nil
            }
        }

        let gMin = gradeFromAge(ageMin?.value)
        let gMax = gradeFromAge(ageMax?.value)

        // Legacy single grade for backward-compat code
        let singleGrade = Self.deriveGrade(fromAgeMin: ageMin?.value)

        // Build a clean grade range
        let derivedGradeMin: Int?
        let derivedGradeMax: Int?
        switch (gMin, gMax) {
        case let (min?, max?):
            derivedGradeMin = min
            derivedGradeMax = max
        case let (min?, nil):
            derivedGradeMin = min
            derivedGradeMax = min
        case let (nil, max?):
            derivedGradeMin = max
            derivedGradeMax = max
        default:
            derivedGradeMin = nil
            derivedGradeMax = nil
        }

        return Material(
            id: id,
            category: (format?.capitalized).nonEmpty ?? type.capitalized,
            title: name,

            grade: singleGrade,                 // keep legacy single grade
            gradeMin: derivedGradeMin,
            gradeMax: derivedGradeMax,

            duration: durationMinMinutes?.value ?? 0,

            // German labels
            devices: resourcesNeeded
                .compactMap {
                    let raw = $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    return Device(rawValue: raw)?.label
                }
                .filter { !$0.isEmpty },

            isFavorite: isFavorite,

            topics: topics
                .compactMap {
                    let raw = $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    return Topic(rawValue: raw)?.label
                }
                .filter { !$0.isEmpty },

            ageMin: ageMin?.value,
            ageMax: ageMax?.value,
            durationMax: durationMaxMinutes?.value,
            prepTimeMinutes: prepTimeMinutes?.value,
            cleanupTimeMinutes: cleanupTimeMinutes?.value,
            breakAfter: breakAfter?.value,
            mentalLoad: mapLevel(mentalLoad),
            physicalEnergy: mapLevel(physicalEnergy),
            bloomLevel: bloomLevel,
            source: source,
            documentId: documentId?.value
        )
    }

    private static func deriveGrade(fromAgeMin age: Int?) -> Int {
        guard let age = age else { return 0 }
        // 6→1, 7→2, 8→3, 9→4 (legacy single grade)
        return max(1, min(4, age - 5))
    }
}

private extension Optional where Wrapped == String {
    var nonEmpty: String? {
        switch self?.trimmingCharacters(in: .whitespacesAndNewlines) {
        case .some(let s) where !s.isEmpty: return s
        default: return nil
        }
    }
}
