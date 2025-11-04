//
//  StepProgressBar.swift
//  Master
//
//  Created by Minkyoung Park on 14.10.25.
//

import SwiftUI

struct StepProgressBar: View {
    let current: WizardStep
    var isStepEnabled: (WizardStep) -> Bool = { _ in true }
    let onSelect: (WizardStep) -> Void

    private let accent = Color(red: 96/255, green: 165/255, blue: 250/255)
    private let circleSize: CGFloat = 30
    private let connectorWidth: CGFloat = 28
    var planIconName: String = "lightbulb"

    var body: some View {
        VStack(spacing: 10) {
            // Each step vertically aligned: circle + label below it
            HStack(spacing: 0) {
                ForEach(Array(WizardStep.progressSteps.enumerated()), id: \.element) { idx, step in
                    let enabled   = isStepEnabled(step)
                    let currentProgressIndex = current.progressIndex ?? -1
                    let isPassed  = idx <= currentProgressIndex
                    let isCurrent = idx == currentProgressIndex

                    VStack(spacing: 6) {
                        Button {
                            if enabled { onSelect(step) }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(isCurrent ? accent.opacity(0.18)
                                         : (isPassed ? accent.opacity(0.12) : Color(.systemBackground)))
                                    .overlay(
                                        Circle().stroke(isCurrent ? accent :
                                            (isPassed ? accent : Color.gray.opacity(0.55)),
                                            lineWidth: isCurrent ? 2.0 : 1.5)
                                    )
                                    .frame(width: circleSize, height: circleSize)

                                Text("\(idx + 1)")
                                    .font(.system(size: 13, weight: isCurrent ? .bold : .semibold))
                                    .foregroundColor(
                                        enabled
                                        ? (isPassed ? accent : Color.gray.opacity(0.9))
                                        : Color.gray.opacity(0.5)
                                    )
                                    .accessibilityHidden(true)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!enabled)
                        .opacity(enabled ? 1.0 : 0.9)

                        // Label directly below circle
                        Group {
                            if step == .plan {
                                Image(systemName: planIconName)
                                    .font(.system(size: 12, weight: isCurrent ? .bold : .regular))
                            } else {
                                Text(step.title)
                                    .font(.system(size: 11, weight: isCurrent ? .semibold : .regular))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                        }
                        .foregroundColor(colorForLabel(enabled: enabled, isCurrent: isCurrent))
                    }
                    .frame(maxWidth: .infinity)

                    if idx < WizardStep.progressSteps.count - 1 {
                        Rectangle()
                            .fill((idx + 1) <= currentProgressIndex ? accent : Color.gray.opacity(0.55))
                            .frame(width: connectorWidth, height: 2)
                            .offset(y: -circleSize / 2 + 6)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.clear)
    }

    private func colorForLabel(enabled: Bool, isCurrent: Bool) -> Color {
        if isCurrent { return accent }
        if enabled { return Color.gray.opacity(0.9) }
        return Color.gray.opacity(0.5)
    }

    private func accessibilityLabel(for step: WizardStep) -> Text {
        switch step {
        case .start:  return Text("Start")
        case .time:   return Text("Schritt 1: Zeit")
        case .grade:  return Text("Schritt 2: Klasse")
        case .device: return Text("Schritt 3: Geräte")
        case .topic:  return Text("Schritt 4: Themen")
        case .plan:   return Text("Schritt 5: Empfehlungen")
        }
    }
}
