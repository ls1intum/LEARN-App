//
//  RegisterView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 14.07.25.
//

import SwiftUI

struct RegisterView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var errorMessage: String = ""
    @State private var isRegistering = false
    @State private var navigateToLogin = false
    @State private var registeredEmail: String? = nil

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState

    private var isFormValid: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               isValidEmail(email)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.(de|com|org|net)"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private var isFormFilled: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty
    }

    private var emailError: String? {
        if email.isEmpty || isValidEmail(email) { return nil }
        return "Ungültige E-Mail-Adresse."
    }
    
    @MainActor
    private func handleRegister() async {
        guard isFormValid else {
            if let error = emailError {
                errorMessage = error
            }
            return
        }
        
        isRegistering = true
        errorMessage = ""
        
        do {
            let client = APIClient()
            let authAPI = LiveAuthAPI(api: client)
            let response = try await authAPI.registerTeacher(
                email: email,
                firstName: firstName,
                lastName: lastName
            )
            
            isRegistering = false
            registeredEmail = email
            navigateToLogin = true
            
        } catch {
            isRegistering = false
            if let apiError = error as? APIError {
                if apiError.status == 409 {
                    errorMessage = "Diese E-Mail ist bereits registriert."
                } else {
                    errorMessage = "Registrierung fehlgeschlagen. Bitte versuche es erneut."
                }
            } else {
                errorMessage = "Registrierung fehlgeschlagen. Bitte versuche es erneut."
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Headline
                    Text("Registrieren")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 36/255, green: 37/255, blue: 44/255)) // #24252C
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 40)

                    Text("Registriere dich,\num deine Planung zu speichern.")
                        .font(.system(size: 17))
                        .foregroundColor(Color(red: 91/255, green: 91/255, blue: 91/255))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                    // Form Fields
                    Group {
                        FormField(title: "Vorname", text: $firstName)
                        FormField(title: "Nachname", text: $lastName)
                        FormField(title: "E-Mail Adresse", text: $email, keyboardType: .emailAddress)
                        if let error = emailError {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    }

                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 10)
                    }

                    // Register Button
                    Button(action: {
                        Task {
                            await handleRegister()
                        }
                    }) {
                        if isRegistering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Konto erstellen")
                        }
                    }
                    .disabled(!isFormFilled || isRegistering)
                    .buttonStyle(CurvedFilledButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    // Hidden NavigationLink for programmatic navigation
                    NavigationLink(
                        destination: LoginView(prefillEmail: registeredEmail, showSuccessMessage: registeredEmail != nil),
                        isActive: $navigateToLogin
                    ) {
                        EmptyView()
                    }
                    .hidden()

                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Text Field Components

struct FormField: View {
    var title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(red: 75/255, green: 83/255, blue: 104/255))

            TextField(title, text: $text)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .stroke(Color.gray.opacity(0.6))
                )
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
}
