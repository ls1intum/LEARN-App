//
//  GradeStepView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI

struct GradeStepView: View {
    @Binding var selectedGrade: GradeLevel?
    var onNext: () -> Void

    private var selectedGradeTitle: String {
        selectedGrade?.rawValue ?? "Klassenstufe wählen"
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Für welche Klassenstufe planst du die Unterrichtseinheit?")
                .stepTitle()

            Menu {
                Picker(selection: $selectedGrade, label: EmptyView()) {
                    ForEach(GradeLevel.allCases) { grade in
                        Text(grade.rawValue).tag(Optional(grade))
                    }
                }
                .pickerStyle(.inline)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "graduationcap")
                        .foregroundStyle(.black)

                    Text(selectedGrade?.rawValue ?? "Klassenstufe wählen")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(selectedGrade == nil ? .secondary : Color.black)
                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColors.tagBG)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppColors.primary.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
            }
            .tint(AppColors.primary)
            .padding(.horizontal, 35)
            .padding(.vertical, 12)
            .environment(\.font, .system(size: 17))


            Spacer()

            Button("Weiter") { onNext() }
                .disabled(selectedGrade == nil)
                .buttonStyle(CurvedFilledButtonStyle())
                .padding(.bottom, 50)
        }
    }
}

