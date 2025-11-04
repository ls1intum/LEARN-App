//
//  WizardStep.swift
//  Master
//
//  Created by Minkyoung Park on 14.10.25.
//

import SwiftUI

enum WizardStep: Int, CaseIterable, Identifiable {
    case start = 0, time, grade, device, topic, plan
    var id: Int { rawValue }

    // Progress bar steps (excluding start)
    static var progressSteps: [WizardStep] {
        return [.time, .grade, .device, .topic, .plan]
    }
    
    // Get the progress bar index for this step (0-based for progress bar)
    var progressIndex: Int? {
        return WizardStep.progressSteps.firstIndex(of: self)
    }

    var title: String {
        switch self {
        case .start:  return "Start"
        case .time:   return "Zeit"
        case .grade:  return "Klasse"
        case .device: return "Geräte"
        case .topic:  return "Thema"
        case .plan:   return "Vorschläge"
        }
    }
}
