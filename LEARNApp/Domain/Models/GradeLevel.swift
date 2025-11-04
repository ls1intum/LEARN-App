//
//  GradeLevel.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import Foundation

enum GradeLevel: String, CaseIterable, Identifiable {
    case grade1 = "1. Klasse"
    case grade2 = "2. Klasse"
    case grade3 = "3. Klasse"
    case grade4 = "4. Klasse"

    var id: String { rawValue }
    var value: Int {
        switch self {
            case .grade1: 1
            case .grade2: 2
            case .grade3: 3
            case .grade4: 4
        }
    }
}
