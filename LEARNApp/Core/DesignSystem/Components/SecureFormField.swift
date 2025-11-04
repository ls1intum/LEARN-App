//
//  SecureFormField.swift
//  Master
//
//  Created by Minkyoung Park on 13.10.25.
//

import SwiftUI

struct SecureFormField: View {
    var title: String
    var placeholder: String? = nil
    @Binding var text: String
    @Binding var showText: Bool

    var body: some View {
        let ph = placeholder ?? title
        
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(red: 75/255, green: 83/255, blue: 104/255))

            HStack {
                Group {
                    if showText {
                        TextField(ph, text: $text)
                            .textContentType(.newPassword)
                            .autocorrectionDisabled(true)
                            .autocapitalization(.none)
                    } else {
                        SecureField(ph, text: $text)
                            .textContentType(.newPassword)
                            .autocorrectionDisabled(true)
                            .autocapitalization(.none)
                    }
                }

                Button(action: {
                    showText.toggle()
                }) {
                    Image(systemName: showText ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .stroke(Color.gray.opacity(0.6))
            )
        }
    }
}
