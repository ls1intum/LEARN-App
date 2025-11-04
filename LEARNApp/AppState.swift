//
//  AppState.swift
//  MasterApp
//
//  Created by Minkyoung Park on 10.07.25.
//

import SwiftUI
import Foundation

final class AppState: ObservableObject {
    // Session state
    @Published var isLoggedIn: Bool = (AuthStorage.accessToken != nil)
    @Published var user: APIUser?

    // Convenience for your existing UI bindings
    @Published var userId: Int = 0
    @Published var userEmail: String = ""
    @Published var userFirstName: String = ""
    @Published var userLastName: String = ""

    // Auth UI status
    @Published var isLoadingAuth = false
    @Published var authError: String?

    // DI
    private let auth: AuthAPI

    init(auth: AuthAPI = LiveAuthAPI(api: APIClient())) {
        self.auth = auth
    }

    // Call this once on app start (e.g., in MasterApp/MainTabView .task)
    @MainActor
    func bootstrap() async {
        guard AuthStorage.accessToken != nil else {
            isLoggedIn = false
            user = nil
            return
        }
        await runAuth {
            // Try me(); if token is expired, try refresh then me()
            do {
                let u = try await self.auth.me()
                self.apply(user: u)
            } catch {
                let _ = try await self.auth.refresh()
                let u = try await self.auth.me()
                self.apply(user: u)
            }
        }
    }

    // MARK: - Auth flows

    /// Dev account (password)
    func loginPassword(email: String, password: String) async {
        await runAuth {
            let u = try await self.auth.loginWithPassword(email: email, password: password)
            await MainActor.run { self.apply(user: u) }
        }
    }

    /// Teacher email → request code
    func requestCode(email: String) async {
        await runAuth {
            try await self.auth.requestVerificationCode(email: email)
        }
    }

    /// Teacher email + code → login
    func verifyCode(email: String, code: String) async {
        await runAuth {
            let u = try await self.auth.verifyEmailCode(email: email, code: code)
            await MainActor.run { self.apply(user: u) }
        }
    }

    /// Explicit refresh (rarely needed if you use bootstrap and handle 401s)
    func refreshSession() async {
        await runAuth {
            let _ = try await self.auth.refresh()
            let u = try await self.auth.me()
            await MainActor.run { self.apply(user: u) }
        }
    }

    /// Logout server-side and clear local tokens/state
    func logout() async {
        await MainActor.run { self.isLoadingAuth = true }
        defer { Task { @MainActor in self.isLoadingAuth = false } }
        do { try await auth.logout() } catch { }
        await MainActor.run {
            AuthStorage.clear()
            user = nil
            userId = 0
            userEmail = ""; userFirstName = ""; userLastName = ""
            isLoggedIn = false
        }
    }


    // MARK: - Internals

    private func apply(user u: APIUser) {
        user = u
        userId = u.id
        userEmail = u.email
        if let f = u.firstName { userFirstName = f } else { userFirstName = "" }
        if let l = u.lastName { userLastName = l } else { userLastName = "" }
        isLoggedIn = true
        authError = nil
    }

    private func runAuth(_ work: @escaping () async throws -> Void) async {
        await MainActor.run {
            self.isLoadingAuth = true
            self.authError = nil
        }
        defer { Task { @MainActor in self.isLoadingAuth = false } }
        do {
            try await work()
        } catch {
            print("🔴 Auth error caught: \(error)")
            if let apiError = error as? APIError {
                print("🔴 APIError - status: \(apiError.status), message: \(apiError.message)")
            }
            let readable = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            print("🔴 Readable error: \(readable)")
            await MainActor.run { self.authError = readable }
        }
    }
}

// ---- Deprecated local-only auth (kept to avoid breaking compiles). Remove once all call sites are updated. ----
extension AppState {
    @available(*, deprecated, message: "Use loginPassword/email-code with backend.")
    func register(email: String, password: String, firstName: String, lastName: String) -> Bool { false }

    @available(*, deprecated, message: "Use loginPassword(email:password:) with backend.")
    func login(email: String, password: String) -> Bool { false }

    @available(*, deprecated, message: "Use backend endpoint for password change (if available).")
    func changePassword(current: String, new: String) -> Bool { false }
}
