//
//  ProfileView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.isLoggedIn {
            LoggedInProfileView()
        } else {
            LoggedOutProfileView()
        }
    }
}
