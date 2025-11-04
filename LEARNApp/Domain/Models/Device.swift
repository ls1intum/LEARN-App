//
//  Device.swift
//  Master
//
//  Created by Minkyoung Park on 15.09.25.
//

import Foundation

enum Device: String, CaseIterable, Identifiable {
    case computers
    case tablets
    case handouts
    case blocks
    case electronics
    case stationery

    var id: String { rawValue }

    var label: String {
        switch self {
        case .computers:    return "Computer"
        case .tablets:      return "Tablet"
        case .handouts:     return "Ausdrucke"
        case .blocks:       return "Bausteine"
        case .electronics:  return "Elektronikbauteile"
        case .stationery:   return "Schreibwaren"
        }
    }
}
