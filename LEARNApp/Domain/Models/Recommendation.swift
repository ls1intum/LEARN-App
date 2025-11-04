//
//  Recommendation.swift
//  Master
//
//  Created by Minkyoung Park on 25.09.25.
//

import Foundation

struct Recommendation: Identifiable, Equatable {
    var id: String { "rec-\(score ?? -1)-\(activities.first?.id ?? -1)" }
    var activities: [Material]
    var score: Double?
}
