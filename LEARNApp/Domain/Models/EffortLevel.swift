//
//  EffortLevel.swift
//  Master
//
//  Created by Minkyoung Park on 13.10.25.
//

import Foundation

enum EffortLevel: String, Codable {
    case low, medium, high
    var label: String {
        switch self {
        case .low:    return "niedrig"
        case .medium: return "mittel"
        case .high:   return "hoch"
        }
    }
}
