//
//  EditProfileView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 26.07.25.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var errorMessage: String = ""
    @State private var isSaving = false
    
    private let pageBG = Color(red: 80/255, green: 156/255, blue: 254/255).opacity(0.07)

    init(appState: AppState) {
        _firstName = State(initialValue: appState.userFirstName)
        _lastName = State(initialValue: appState.userLastName)
        _email = State(initialValue: appState.userEmail)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Profil bearbeiten")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 36/255, green: 37/255, blue: 44/255))
                    .padding(.top, 40)

                FormField(title: "Vorname", text: $firstName)
                FormField(title: "Nachname", text: $lastName)
                FormField(title: "E-Mail Adresse", text: $email, keyboardType: .emailAddress)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Button(action: {
                    Task {
                        await saveProfile()
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Speichern")
                    }
                }
                .disabled(isSaving)
                .buttonStyle(CurvedFilledButtonStyle())
                .padding(.top, 20)

                Spacer()
            }
            .padding(.horizontal, 40)
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .automatic)
        .toolbarColorScheme(.light, for: .navigationBar)
        .background(pageBG.ignoresSafeArea())
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.(de|com|org|net)"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    @MainActor
    private func saveProfile() async {
        guard isValidEmail(email) else {
            errorMessage = "Bitte gib eine gültige E-Mail Adresse ein."
            return
        }
        
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty,
              !lastName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Vor- und Nachname dürfen nicht leer sein."
            return
        }
        
        isSaving = true
        errorMessage = ""
        
        do {
            let client = APIClient()
            let authAPI = LiveAuthAPI(api: client)
            
            // Determine what changed
            let emailChanged = email != appState.userEmail
            let firstNameChanged = firstName != appState.userFirstName
            let lastNameChanged = lastName != appState.userLastName
            
            // Prepare values - send null for unchanged fields, actual values for changed fields
            let emailToSend: String? = emailChanged ? email : nil
            let firstNameToSend: String? = firstNameChanged ? firstName : nil
            let lastNameToSend: String? = lastNameChanged ? lastName : nil
            
            let updatedUser = try await authAPI.updateMe(
                email: emailToSend,
                firstName: firstNameToSend,
                lastName: lastNameToSend,
                password: nil
            )
            
            // Update app state with response from backend
            appState.userEmail = updatedUser.email
            appState.userFirstName = updatedUser.firstName ?? firstName
            appState.userLastName = updatedUser.lastName ?? lastName
            
            // Save to UserDefaults
            UserDefaults.standard.set(appState.userFirstName, forKey: "user_first_name")
            UserDefaults.standard.set(appState.userLastName, forKey: "user_last_name")
            UserDefaults.standard.set(appState.userEmail, forKey: "user_email")
            
            isSaving = false
            presentationMode.wrappedValue.dismiss()
            
        } catch {
            isSaving = false
            if let apiError = error as? APIError {
                if apiError.status == 409 {
                    errorMessage = "Diese E-Mail wird bereits verwendet."
                } else {
                    errorMessage = "Speichern fehlgeschlagen. Bitte versuche es erneut."
                }
            } else {
                errorMessage = "Speichern fehlgeschlagen. Bitte versuche es erneut."
            }
        }
    }
}
