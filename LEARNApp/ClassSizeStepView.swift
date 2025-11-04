//
//  ClassSizeStepView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI

struct ClassSizeStepView: View {
    @Binding var classSize: Int
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Text("Wie viele Schüler:innen sind in deiner Klasse?")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding()

            Stepper(value: $classSize, in: 5...40, step: 1) {
                Text("\(classSize) Schüler:innen")
                    .font(.title2.weight(.medium))
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)

            Spacer()
            
            Button("Weiter") {
                onNext()
            }
            .buttonStyle(CurvedFilledButtonStyle())
            .padding(.bottom, 50)
        }
    }
}
