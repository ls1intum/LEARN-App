//
//  DeviceStepView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 06.09.25.
//

import SwiftUI

struct DeviceStepView: View {
    @Binding var selected: Set<Device>
    var onNext: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Welche Geräte stehen dir zur Verfügung?")
                .stepTitle()
            
            HStack {
                Spacer()
                Button(action: {
                    selected = Set(Device.allCases)
                }) {
                    Text("Alle auswählen")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
            }
            .padding(.top, -16)

            LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                ForEach(Device.allCases) { device in
                    Chip(
                        label: device.label,
                        isSelected: selected.contains(device)
                    ) {
                        if selected.contains(device) {
                            if selected.count > 1 { selected.remove(device) }
                        } else {
                            selected.insert(device)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .onAppear {
                if selected.isEmpty { selected = Set(Device.allCases) }
            }

            Spacer()

            Button("Weiter") { onNext() }
                .buttonStyle(CurvedFilledButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .disabled(selected.isEmpty)
        }
    }
}
