//
//  LoggedOutView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 14.07.25.
//

import SwiftUI

struct LoggedOutView: View {
    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                Text("**Du nutzt die App aktuell ohne Konto.**\n\nMelde dich an,\num alle Funktionen nutzen zu können:")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(Color(red: 75/255, green: 83/255, blue: 104/255)) // #4B5368

                VStack(alignment: .leading, spacing: 12) {
                    Label("Deine Empfehlungen\nals Favoriten speichern", systemImage: "heart")
                    Label("Überblick über alle bisherigen\nSuchanfragen behalten", systemImage: "clock.arrow.circlepath")
                    Label("Lieblingsmaterialien schnell\nwiederfinden", systemImage: "star")
                }
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color(red: 75/255, green: 83/255, blue: 104/255))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 164/255, green: 173/255, blue: 255/255), lineWidth: 1)
            )
            .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 12) {
                NavigationLink(destination: RegisterView()) {
                    Text("Konto erstellen")
                        .frame(width: 320, height: 52)
                }
                .buttonStyle(CurvedFilledButtonStyle())

                NavigationLink(destination: LoginView()) {
                    Text("Schon registriert? Jetzt einloggen")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .underline()
                        .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                }
            }
            .padding(.bottom, 34)
        }
    }
}
