//
//  Topic.swift
//  Master
//
//  Created by Minkyoung Park on 12.10.25.
//

import Foundation

enum Topic: String, CaseIterable, Identifiable {
    case decomposition
    case patterns
    case abstraction
    case algorithms

    var id: String { rawValue }

    var label: String {
        switch self {
        case .decomposition: return "Problemzerlegung"
        case .patterns:      return "Muster"
        case .abstraction:   return "Abstraktion"
        case .algorithms:    return "Algorithmen"
        }
    }
}
