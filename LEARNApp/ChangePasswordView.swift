//
//  ChangePasswordView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 06.09.25.
//

import SwiftUI

struct ChangePasswordView: View {
    // Inputs
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    // Toggles for eye icon
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false

    // UI state
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    @State private var isSaving: Bool = false

    // DI
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // Background
    private let pageBG = Color(red: 80/255, green: 156/255, blue: 254/255).opacity(0.07)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Passwort ändern")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 36/255, green: 37/255, blue: 44/255))
                    .padding(.top, 40)

                VStack(alignment: .leading, spacing: 8) {
                    SecureFormField(
                                       title: "Neues Passwort",
                                       placeholder: "Passwort eingeben",
                                       text: $newPassword,
                                       showText: $showNewPassword
                                   )
                }

                VStack(alignment: .leading, spacing: 8) {
                    SecureFormField(
                                        title: "Neues Passwort bestätigen",
                                        placeholder: "Wiederholen",
                                        text: $confirmPassword,
                                        showText: $showConfirmPassword
                                    )
                }

                // Live-Checks
                VStack(alignment: .leading, spacing: 6) {
                    validationRow("Mindestens 6 Zeichen", ok: newPassword.count >= 6)
                    validationRow("Enthält Buchstaben und Zahlen", ok: containsLetterAndNumber(newPassword))
                    validationRow("Bestätigung stimmt überein", ok: !confirmPassword.isEmpty && newPassword == confirmPassword)
                }
                .padding(.top, 4)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 4)
                }

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if isSaving { ProgressView().padding(.trailing, 6) }
                        Text(isSaving ? "Speichere…" : "Passwort speichern").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CurvedFilledButtonStyle())
                .disabled(!isValid)
                .padding(.top, 10)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 0) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                        Text("Zurück")
                            .font(.system(size: 14))
                    }
                    .fixedSize()
                }
                .foregroundColor(.blue)
                .buttonStyle(.plain)
            }
        }
        .scrollContentBackground(.hidden)
        .background(pageBG.ignoresSafeArea())
        .tint(AppColors.primaryDark)
        .alert("Passwort geändert", isPresented: $showSuccess) {
            Button("OK") { }
        } message: {
            Text("Dein Passwort wurde erfolgreich aktualisiert.")
        }
        .tint(AppColors.primaryDark)
    }

    // MARK: - Validation
    private var isValid: Bool {
        guard newPassword.count >= 6 else { return false }
        guard containsLetterAndNumber(newPassword) else { return false }
        guard !confirmPassword.isEmpty, newPassword == confirmPassword else { return false }
        return true
    }

    private func containsLetterAndNumber(_ s: String) -> Bool {
        s.contains(where: \.isLetter) && s.contains(where: \.isNumber)
    }

    @ViewBuilder
    private func validationRow(_ text: String, ok: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: ok ? "checkmark.circle.fill" : "circle")
                .imageScale(.medium)
                .foregroundStyle(ok ? AppColors.primaryDark : .secondary) // blue when OK
            Text(text).font(.footnote)
                .foregroundStyle(ok ? .primary : .secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(text) \(ok ? "erfüllt" : "nicht erfüllt")"))
    }

    // MARK: - Networking
    @MainActor
    private func submit() async {
        guard isValid else {
            errorMessage = "Bitte prüfe deine Eingaben."
            return
        }
        isSaving = true
        errorMessage = ""
        defer { isSaving = false }

        do {
            let client = APIClient()
            let authAPI = LiveAuthAPI(api: client)
            
            let _ = try await authAPI.updateMe(
                email: nil,
                firstName: nil,
                lastName: nil,
                password: newPassword
            )

            showSuccess = true
            newPassword = ""; confirmPassword = ""
        } catch let apiErr as APIError {
            errorMessage = apiErr.message
        } catch {
            errorMessage = "Etwas ist schiefgelaufen. Bitte versuche es erneut."
        }
    }
}
