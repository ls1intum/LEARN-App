//
//  FilterPicker.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import SwiftUI

struct FilterPicker: View {
    var title: String
    var options: [String]
    @Binding var selection: String?
    
    var allLabel: String? = nil

    var body: some View {
        let allText = allLabel ?? "Alle \(title)"
        Menu {
            Button(allText, action: { selection = nil })
            ForEach(options, id: \.self) { opt in
                Button(opt, action: { selection = opt })
            }
        } label: {
            HStack {
                Text(selection ?? title).font(Typography.bodyB)
                Spacer()
                Image(systemName: "chevron.down")
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border, lineWidth: 1))
        }
    }
}
