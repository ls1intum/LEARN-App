//
//  LoginView.swift
//  MasterApp
//
//  Created by Minkyoung Park on 14.07.25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var prefillEmail: String? = nil
    var showSuccessMessage: Bool = false

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword: Bool = false

    @State private var code = ""
    @State private var showCodeInput = false

    enum Mode { case emailCode, password }
    @State private var mode: Mode = .emailCode
    
    @State private var displaySuccessMessage = false

    @FocusState private var focused: Field?
    enum Field: Hashable { case email, password }

    var body: some View {
        Group {
            if displaySuccessMessage || showSuccessMessage {
                // When coming from registration, don't wrap in NavigationView
                contentView
                    .navigationBarBackButtonHidden(true)
            } else {
                // Normal flow - wrap in NavigationView
                NavigationView {
                    contentView
                }
            }
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                
                // Success Message (after registration)
                if displaySuccessMessage {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 20))
                            Text("Registrierung erfolgreich!")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        Text("Überprüfe deine E-Mails für den Bestätigungscode.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.top, 8)
                }

                // E-Mail field
                FormField(title: "E-Mail-Adresse", text: $email, keyboardType: .emailAddress)
                    .focused($focused, equals: .email)
                    .submitLabel(mode == .password ? .next : .done)
                    .onSubmit { focusNextFromEmail() }
                    .padding(.top, 8)
                    .disabled(displaySuccessMessage) // Disable if coming from registration

                Group {
                    switch mode {
                    case .password:
                        passwordSection
                    case .emailCode:
                        emailCodeSection
                    }
                }
                .padding(.top, 4)

                if appState.isLoadingAuth { ProgressView().padding(.top, 4) }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            if let prefill = prefillEmail {
                email = prefill
            }
            displaySuccessMessage = showSuccessMessage
            
            if !displaySuccessMessage {
                focused = .email
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anmelden")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 36/255, green: 37/255, blue: 44/255))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)

            Text("Melde dich an, \num deine Planung fortzusetzen.")
                .font(.system(size: 17))
                .foregroundColor(Color(red: 91/255, green: 91/255, blue: 91/255))
        }
    }

    // MARK: - Sections
    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SecureFormField(title: "Passwort", text: $password, showText: $showPassword)
                .focused($focused, equals: .password)
                .submitLabel(.go)
                .onSubmit { Task { await loginWithPassword() } }

            Button(action: { Task { await loginWithPassword() } }) {
                Text(appState.isLoadingAuth ? "Bitte warten…" : "Einloggen")
            }
            .buttonStyle(CurvedFilledButtonStyle())
            .disabled(!isValidAdminForm || appState.isLoadingAuth)
            .padding(.top, 8)

            Button(action: { switchToEmailCode() }) {
                Text("Mit Bestätigungscode einloggen")
                    .underline()
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }
    }

    private var emailCodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !showCodeInput {
                // Initial state: Send code button
                Button(action: { Task { await startEmailCodeFlow() } }) {
                    Text(appState.isLoadingAuth ? "Bitte warten…" : "Code zum Einloggen senden")
                }
                .buttonStyle(CurvedFilledButtonStyle())
                .disabled(!isValidEmail || appState.isLoadingAuth)
                .padding(.top, 8)

                Button(action: { switchToPassword() }) {
                    Text("Mit Passwort einloggen")
                        .underline()
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            } else {
                // Code sent: Show input fields
                VStack(alignment: .leading, spacing: 12) {
                    Text("Falls ein Konto mit \(email) existiert, haben wir einen Bestätigungscode gesendet.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
 
                    // OTP
                    OTPCodeInputSixFields(code: $code, length: 6)
                        .padding(.vertical, 8)

                    Button(action: { Task { await verifyCode() } }) {
                        Text(appState.isLoadingAuth ? "Bitte warten…" : "Code bestätigen und einloggen")
                    }
                    .buttonStyle(CurvedFilledButtonStyle())
                    .disabled(code.count != 6 || appState.isLoadingAuth)

                    HStack(spacing: 16) {
                        Button(action: { Task { await resendCode() } }) {
                            Text("Code erneut senden")
                                .font(.footnote)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)

                        Button(action: { cancelCodeFlow() }) {
                            Text("Abbrechen")
                                .font(.footnote)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                .onAppear {
                    focused = nil
                }
            }
        }
    }

    // MARK: - Actions
    @MainActor
    private func loginWithPassword() async {
        guard isValidAdminForm else { return }
        await appState.loginPassword(email: trimmedEmail, password: password)
        if appState.isLoggedIn { dismiss() }
    }

    @MainActor
    private func startEmailCodeFlow() async {
        guard isValidEmail else { return }
        code = ""
        await appState.requestCode(email: trimmedEmail)
        if appState.authError?.isEmpty ?? true {
            withAnimation {
                showCodeInput = true
            }
            focused = nil
        } else {
            showCodeInput = false
        }
    }

    @MainActor
    private func verifyCode() async {
        guard code.count == 6 else { return }
        await appState.verifyCode(email: trimmedEmail, code: code)
        if appState.isLoggedIn {
            dismiss()
        }
    }

    @MainActor
    private func resendCode() async {
        guard isValidEmail else { return }
        code = "" // reset code for new input
        await appState.requestCode(email: trimmedEmail)
    }

    private func cancelCodeFlow() {
        withAnimation {
            showCodeInput = false
            code = ""
        }
        focused = .email
    }

    private func switchToPassword() {
        mode = .password
        showCodeInput = false
        code = ""
        focused = .password
    }

    private func switchToEmailCode() {
        mode = .emailCode
        showCodeInput = false
        code = ""
        focused = .email
    }

    private func focusNextFromEmail() {
        switch mode {
        case .password: focused = .password
        case .emailCode: focused = nil
        }
    }

    // MARK: - Validation
    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValidEmail: Bool {
        let e = trimmedEmail
        return e.contains("@") && e.contains(".") && e.count >= 5
    }
    private var isValidAdminForm: Bool { isValidEmail && !password.isEmpty }
}

// MARK: - Six-Fields-OTP
private struct OTPCodeInputSixFields: View {
    @Binding var code: String
    let length: Int

    @State private var text: String
    @FocusState private var isFocused: Bool

    init(code: Binding<String>, length: Int) {
        self._code = code
        self.length = length
        let initial = String(code.wrappedValue.filter(\.isNumber).prefix(length))
        _text = State(initialValue: initial)
    }

    var body: some View {
        ZStack(alignment: .center) {
            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { idx in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(currentIndex == idx && isFocused ? Color.blue.opacity(0.6) : Color(.systemGray4), lineWidth: 1)
                            .frame(width: 44, height: 52)

                        Text(character(at: idx))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .frame(width: 44, height: 52)
                            .contentTransition(.identity)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        DispatchQueue.main.async { isFocused = true }
                    }
                    .accessibilityLabel("Codefeld \(idx + 1) von \(length)")
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                DispatchQueue.main.async { isFocused = true }
            }

            TextField("", text: $text)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.02)
                .allowsHitTesting(false)
        }
        .onChange(of: text) { oldValue, newValue in
            let filtered = newValue.filter(\.isNumber)
            let clamped = String(filtered.prefix(length))
            if clamped != text { text = clamped }
            if clamped != code { code = clamped }
        }
        .onChange(of: code) { oldValue, newValue in
            let filtered = newValue.filter(\.isNumber)
            let clamped = String(filtered.prefix(length))
            if clamped != text { text = clamped }
            if clamped != code { code = clamped }
        }
        .onAppear {
            if text.isEmpty {
                DispatchQueue.main.async { isFocused = true }
            }
        }
    }

    // MARK: - Helpers

    private var currentIndex: Int {
        min(text.count, length - 1)
    }

    private func character(at index: Int) -> String {
        if index < text.count {
            let i = text.index(text.startIndex, offsetBy: index)
            return String(text[i])
        } else {
            return "" 
        }
    }
}
