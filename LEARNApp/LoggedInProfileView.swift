//
//  LoggedInProfileView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 11.07.25.
//

import SwiftUI

struct LoggedInProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDeleteAlert = false
    @State private var showLogoutAlert = false
    @State private var isDeletingAccount = false
    @State private var deleteError: String?

    let profileBG = Color(red: 80/255, green: 156/255, blue: 254/255).opacity(0.07)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Profil")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 36/255, green: 37/255, blue: 44/255))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 40)

                    NavigationLink {
                        EditProfileView(appState: appState)
                    } label: {
                        ProfileHeaderCard(
                            initials: initials(from: appState.userFirstName, appState.userLastName),
                            name: "\(appState.userFirstName) \(appState.userLastName)",
                            email: appState.userEmail
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    SettingsCard {
                        NavigationLink {
                            SearchHistoryView()
                        } label: {
                            RowContent(icon: "clock.arrow.circlepath", title: "Vergangene Suchanfragen")
                        }
                        .buttonStyle(.plain)
                        SettingsDivider()
                        NavigationLink {
                                FavoritesView()
                            } label: {
                                RowContent(icon: "heart", title: "Favoriten")
                            }
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    SettingsCard {
                        NavigationLink {
                            ChangePasswordView()
                        } label: {
                            RowContent(icon: "lock", title: "Passwort ändern")
                        }
                        .buttonStyle(.plain)
                        SettingsDivider()
                        Button {
                            showLogoutAlert = true
                        } label: {
                            RowContent(icon: "rectangle.portrait.and.arrow.right", title: "Ausloggen")
                        }
                        .buttonStyle(.plain)
                        .alert("Wirklich ausloggen?", isPresented: $showLogoutAlert) {
                            Button("Abbrechen", role: .cancel) { }
                            Button("Ausloggen", role: .destructive) {
                                Task { await appState.logout() }
                            }
                        } message: {
                            Text("Gespeicherte Pläne bleiben erhalten.")
                        }

                        SettingsDivider()
                        Button {
                            showDeleteAlert = true
                        } label: {
                            RowContent(icon: "trash", title: "Konto löschen", isDestructive: true)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 24)
                }
            }
            .scrollContentBackground(.hidden)
            .background(profileBG.ignoresSafeArea())
            .alert("Konto wirklich löschen?", isPresented: $showDeleteAlert) {
                Button("Abbrechen", role: .cancel) { 
                    deleteError = nil
                }
                Button("Löschen", role: .destructive) {
                    Task { await deleteAccount() }
                }
                .disabled(isDeletingAccount)
            } message: {
                Text("Dieser Vorgang kann nicht rückgängig gemacht werden.")
            }
            .alert("Fehler", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK") {
                    deleteError = nil
                }
            } message: {
                if let error = deleteError {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Helpers
    private func initials(from first: String, _ last: String) -> String {
        let f = first.first.map { String($0) } ?? ""
        let l = last.first.map { String($0) } ?? ""
        return (f + l).uppercased()
    }
    
    // MARK: - Account Deletion
    @MainActor
    private func deleteAccount() async {
        isDeletingAccount = true
        deleteError = nil
        
        do {
            let client = APIClient()
            let authAPI = LiveAuthAPI(api: client)
            
            try await authAPI.deleteMe()
            
            appState.user = nil
            appState.userId = 0
            appState.userEmail = ""
            appState.userFirstName = ""
            appState.userLastName = ""
            appState.isLoggedIn = false
            
            isDeletingAccount = false
            showDeleteAlert = false
            
        } catch {
            isDeletingAccount = false
            if let apiError = error as? APIError {
                deleteError = "Fehler beim Löschen des Kontos: \(apiError.message)"
            } else {
                deleteError = "Fehler beim Löschen des Kontos. Bitte versuche es erneut."
            }
        }
    }
}

// MARK: - Components

private struct ProfileHeaderCard: View {
    let initials: String
    let name: String
    let email: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemBlue).opacity(0.15))
                Text(initials)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(.systemBlue))
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
                Text(email)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
        )
        
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.white), lineWidth: 1)
        )
    }
}

private struct SettingsRow: View {
    var icon: String
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            RowContent(icon: icon, title: title)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RowContent: View {
    var icon: String
    var title: String
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .frame(width: 24)
                .foregroundStyle(isDestructive ? Color(.systemRed) : Color.primary)

            Text(title)
                .font(.system(size: 17))
                .fontWeight(isDestructive ? .semibold : .regular)
                .foregroundStyle(isDestructive ? Color(.systemRed) : Color.primary)

            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 56)
    }
}
