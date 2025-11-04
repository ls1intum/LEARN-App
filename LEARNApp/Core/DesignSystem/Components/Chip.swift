//
//  Chip.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import SwiftUI

struct Chip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    private let corner: CGFloat = 18

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        // Filled circle = primary brand color, checkmark = white
                        .foregroundStyle(AppColors.primary, Color.white)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(AppColors.primary)
                }

                Text(label)
                    .font(Typography.bodyB)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.9)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(isSelected ? AppColors.tagBG : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner)
                            .stroke(AppColors.primary.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}
