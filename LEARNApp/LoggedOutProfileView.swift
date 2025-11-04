//
//  LoggedOutProfileView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 11.07.25.
//

import SwiftUI

struct LoggedOutProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Profil")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 36/255, green: 37/255, blue: 44/255))
                    .padding(.top, 40)
                    .padding(.horizontal, 20)

                LoggedOutView()
            }
            .navigationBarHidden(true)
        }
    }
}
