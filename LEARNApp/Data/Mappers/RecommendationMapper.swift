//
//  RecommendationMapper.swift
//  Master
//
//  Created by Minkyoung Park on 25.09.25.
//

import Foundation

extension RecommendationBundleDTO {
    func toDomain() -> Recommendation {
        Recommendation(
            activities: activities.map { $0.toMaterial() },
            score: score?.value
        )
    }
}
