//
//  Material.swift
//  Master
//
//  Created by Minkyoung Park on 15.09.25.
//

import Foundation

struct Material: Identifiable, Codable, Equatable {
    let id: Int
    let category: String
    let title: String
    let grade: Int
    let gradeMin: Int?
    let gradeMax: Int?
    let duration: Int     // minutes
    let devices: [String]
    var isFavorite: Bool
    let topics: [String]
    let ageMin: Int?
    let ageMax: Int?
    let durationMax: Int?
    let prepTimeMinutes: Int?
    let cleanupTimeMinutes: Int?
    let breakAfter: Int?
    let mentalLoad: EffortLevel?
    let physicalEnergy: EffortLevel?
    let bloomLevel: String?
    let source: String?
    let documentId: String?
}
