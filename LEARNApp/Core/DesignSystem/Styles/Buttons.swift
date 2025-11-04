//
//  Buttons.swift
//  Master
//
//  Created by Minkyoung Park on 15.09.25.
//

import SwiftUI

struct CurvedFilledButtonStyle: ButtonStyle {
    var backgroundColor: Color = Color(red: 96/255, green: 165/255, blue: 250/255)
    var disabledColor: Color = Color(hex: "#9D9D9D")
    var textColor: Color = .white
    var width: CGFloat = 320
    var height: CGFloat = 52
    var font: Font = .system(size: 16, weight: .bold)

    func makeBody(configuration: Configuration) -> some View {
        CurvedFilledButton(configuration: configuration,
                           backgroundColor: backgroundColor,
                           disabledColor: disabledColor,
                           textColor: textColor,
                           width: width,
                           height: height,
                           font: font)
    }

    private struct CurvedFilledButton: View {
        let configuration: Configuration
        let backgroundColor: Color
        let disabledColor: Color
        let textColor: Color
        let width: CGFloat
        let height: CGFloat
        let font: Font
        @Environment(\.isEnabled) var isEnabled

        var body: some View {
            configuration.label
                .font(font)
                .foregroundColor(textColor)
                .frame(width: width, height: height)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isEnabled ? backgroundColor : disabledColor)
                )
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }
}

// MARK: - Bordered Button Style
struct CurvedBorderedButtonStyle: ButtonStyle {
    var borderColor: Color = Color(red: 96/255, green: 165/255, blue: 250/255)
    var textColor: Color = Color(red: 96/255, green: 165/255, blue: 250/255)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(textColor)
            .frame(width: 320, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Pill Bordered Button Style
struct PillBorderedButtonStyle: ButtonStyle {
    var borderColor: Color = Color(red: 96/255, green: 165/255, blue: 250/255)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(borderColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(borderColor.opacity(0.06)) // ganz leichtes Blau als Füllung
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(borderColor.opacity(configuration.isPressed ? 0.6 : 1.0), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.03 : 0.06), radius: 6, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}


// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}


// Backward-compat to avoid mass edits:
typealias CurvedButtonStyle = CurvedFilledButtonStyle
