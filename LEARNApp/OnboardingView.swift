//
//  OnboardingView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 26.05.25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showMainTab: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                
                Image("onboarding_illustration")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .padding(.horizontal)
                            
                VStack(spacing: 8) {
                    Text("Einfacher planen.\nMehr Zeit fürs Lehren.")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 36/255, green: 37/255, blue: 44/255))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.65)
                        .padding(.horizontal)

                    Text("Finde passende Materialien und behalte den Überblick – alles an einem Ort.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color(red: 110/255, green: 106/255, blue: 124/255))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.65)
                        .padding(.horizontal)
                }
                            
                Button(action: {
                    showMainTab = true
                }) {
                    Text("Los geht’s")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .frame(width: 331, height: 52)
                        .background(Color(red: 96/255, green: 165/255, blue: 250/255))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                VStack(spacing: 8) {
                    NavigationLink(destination: LoginView()) {
                        Text("Schon registriert? Einloggen")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .underline()
                            .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                    }
                    
                    NavigationLink(destination: RegisterView()) {
                        Text("Jetzt registrieren")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .underline()
                            .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                    }
                }
                
                Spacer().frame(height: 24)
            }
            .background(Color.white.ignoresSafeArea())
        }
    }
}
