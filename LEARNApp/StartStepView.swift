//
//  StartStep.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI

struct StartStepView: View {
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Lass uns gemeinsam passende Aktivitäten für deine Klasse finden.")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .padding(25)
                    .padding(.top, 50)
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Image("robot")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 150)
                    .padding(.trailing, 40)
                    .padding(.bottom, 30)
            }
            
            Button("Jetzt starten", action: onNext)
                .buttonStyle(CurvedFilledButtonStyle())
                .padding(.bottom, 50)
        }
    }
}

struct StepTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title3.weight(.semibold))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(25)
    }
}
extension View { func stepTitle() -> some View { self.modifier(StepTitle()) } }
