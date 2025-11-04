//
//  TimeStep.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI

struct TimeStepView: View {
    @Binding var selectedDuration: TimeInterval
    var onNext: () -> Void
    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Wie viel Zeit hast du für die Unterrichtseinheit?")
                .stepTitle()

            DatePicker("", selection: Binding(
                get: {
                    Calendar.current.date(byAdding: .second, value: Int(selectedDuration), to: startOfToday)!
                },
                set: {
                    selectedDuration = $0.timeIntervalSince(startOfToday)
                }
            ), displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 200)
            .environment(\.locale, Locale(identifier: "de_DE"))

            Spacer()
            
            Button("Weiter") {
                onNext()
            }
            .buttonStyle(CurvedFilledButtonStyle())
            .padding(.bottom, 50)

        }
    }
}
