//
//  RecommendationsDTO.swift
//  Master
//
//  Created by Minkyoung Park on 25.09.25.
//

import Foundation

// Top-level response
struct RecommendationsResponseDTO: Decodable {
    let activities: [RecommendationBundleDTO]
    let generatedAt: Date?
    let total: Int?
    // `search_criteria` exists but we don't need it for the UI; omit for simplicity
}

// Each recommendation bundle (a scored set/sequence of activities)
struct RecommendationBundleDTO: Decodable {
    let activities: [ActivityDTO]
    let score: LossyDouble?
    let scoreBreakdown: [String: ScoreBreakdownDTO]?
}

struct ScoreBreakdownDTO: Decodable {
    let category: String?
    let impact: LossyDouble?
    let isPriority: Bool?
    let priorityMultiplier: LossyDouble?
    let score: LossyDouble?
}
