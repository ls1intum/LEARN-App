//
//  PlanningView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI

enum PlanningStep {
    case start, time, grade, devices, topics, plan
}

struct PlanningView: View {
    @State private var currentStep: PlanningStep = .start
    @State private var showProgressBar: Bool = true

    @State private var selectedDuration: TimeInterval = 1800
    @State private var selectedGrade: GradeLevel? = nil
    @State private var selectedDevices: Set<Device> = []
    @State private var selectedTopics: Set<Topic> = []

    var body: some View {
        VStack(spacing: 12) {

            if currentStep != .start {
                StepProgressBar(
                    current: currentStep.asWizard,
                    isStepEnabled: { isEnabled($0) }
                ) { tapped in
                    jump(to: tapped)                        
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .opacity(showProgressBar ? 1 : 0)
                .frame(height: showProgressBar ? nil : 0)
                .clipped()
            }

            Group {
                switch currentStep {
                case .start:
                    StartStepView {
                        currentStep = .time
                    }

                case .time:
                    TimeStepView(selectedDuration: $selectedDuration) {
                        currentStep = .grade
                    }

                case .grade:
                    GradeStepView(selectedGrade: $selectedGrade) {
                        currentStep = .devices
                    }

                case .devices:
                    DeviceStepView(selected: $selectedDevices) {
                        currentStep = .topics
                    }

                case .topics:
                    TopicStepView(selected: $selectedTopics) {
                        currentStep = .plan
                    }

                case .plan:
                    if let grade = selectedGrade {
                        let gradeInt = grade.value // 1...4
                        let durationMinutes = max(1, Int(round(selectedDuration / 60))) // s → min

                        PlanStepView(
                            selectedGrade: gradeInt,
                            selectedDurationMinutes: durationMinutes,
                            selectedDevices: selectedDevices,
                            selectedTopics: selectedTopics,
                            onRestart: {
                                resetAll()
                                currentStep = .start
                            },
                            onBack: {
                                showProgressBar = true
                                currentStep = .topics
                            },
                            showProgressBar: $showProgressBar
                        )
                    } else {
                        GradeStepView(selectedGrade: $selectedGrade) {
                            currentStep = .devices
                        }
                    }
                }
            }
            .padding(.bottom, 8)

            Spacer(minLength: 0)
        }
        .animation(.none, value: showProgressBar)
    }
}

// MARK: - Navigation & Mapping
private extension PlanningView {

    func goBack() {
        switch currentStep {
        case .time:    currentStep = .start
        case .grade:   currentStep = .time
        case .devices: currentStep = .grade
        case .topics:  currentStep = .devices
        case .plan:    currentStep = .topics
        case .start:   break
        }
    }

    func jump(to wizard: WizardStep) {
        guard isEnabled(wizard) else { return }

        let target = PlanningStep.from(wizard)

        if target == .plan && selectedGrade == nil {
            currentStep = .grade
            return
        }
        currentStep = target
    }

    func resetAll() {
        selectedDuration = 1800
        selectedGrade = nil
        selectedDevices = []
        selectedTopics  = []
    }

    // MARK: Enable-Logic for Progress Bar
    func isEnabled(_ step: WizardStep) -> Bool {
        switch step {
        case .start, .time, .grade:
            return true
        case .device, .topic, .plan:
            return selectedGrade != nil
        }
    }
}

// MARK: - Mapping between PlanningStep and WizardStep
private extension PlanningStep {
    var asWizard: WizardStep {
        switch self {
        case .start:   return .start
        case .time:    return .time
        case .grade:   return .grade
        case .devices: return .device
        case .topics:  return .topic
        case .plan:    return .plan
        }
    }

    static func from(_ wizard: WizardStep) -> PlanningStep {
        switch wizard {
        case .start:  return .start
        case .time:   return .time
        case .grade:  return .grade
        case .device: return .devices
        case .topic:  return .topics
        case .plan:   return .plan
        }
    }
}
