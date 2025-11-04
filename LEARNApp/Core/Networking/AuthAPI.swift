//
//  AuthAPI.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import Foundation

struct TokenResponse: Decodable {
    let accessToken: String       // maps from "access_token"
    let refreshToken: String?      // maps from "refresh_token"
    let expiresIn: Int?            // maps from "expires_in"
    let user: APIUser
}

struct APIUser: Decodable {
    let id: Int
    let email: String
    let firstName: String?         // maps from "first_name"
    let lastName: String?          // maps from "last_name"
    let role: String?
    let name: String?
    let isVerified: Bool?          // maps from "is_verified"
    let createdAt: Date?           // "2025-09-23T19:00:26.166Z"
}

struct RegisterResponse: Decodable {
    let message: String
    let userId: Int?               // maps from "user_id"
}

protocol AuthAPI {
    func registerTeacher(email: String, firstName: String, lastName: String) async throws -> RegisterResponse
    func requestVerificationCode(email: String) async throws
    func verifyEmailCode(email: String, code: String) async throws -> APIUser
    func loginWithPassword(email: String, password: String) async throws -> APIUser
    func me() async throws -> APIUser
    func updateUser(userId: Int, email: String?, firstName: String?, lastName: String?, password: String?, role: String?) async throws -> APIUser
    func changePassword(userId: Int, newPassword: String) async throws -> APIUser
    func updateMe(email: String?, firstName: String?, lastName: String?, password: String?) async throws -> APIUser
    func deleteMe() async throws
    func refresh() async throws -> APIUser
    func logout() async throws
}

final class LiveAuthAPI: AuthAPI {
    private let api: APIClient
    init(api: APIClient) { self.api = api }
    
    struct UpdateUserBody: Encodable {
            let email: String?
            let firstName: String?
            let lastName: String?
            let password: String?
            let role: String?
            
            enum CodingKeys: String, CodingKey {
                case email
                case firstName = "first_name"
                case lastName = "last_name"
                case password
                case role
            }
        }
    
    // POST /api/auth/register-teacher
    func registerTeacher(email: String, firstName: String, lastName: String) async throws -> RegisterResponse {
        struct Body: Encodable { 
            let email: String
            let firstName: String
            let lastName: String
            
            enum CodingKeys: String, CodingKey {
                case email
                case firstName = "first_name"
                case lastName = "last_name"
            }
        }
        return try await api.send(.POST, "/api/auth/register-teacher", body: Body(email: email, firstName: firstName, lastName: lastName))
    }

    func updateUser(userId: Int, email: String?, firstName: String?, lastName: String?, password: String?, role: String?) async throws -> APIUser {
        try await api.send(
            .PUT,
            "/api/auth/users/\(userId)",
            body: UpdateUserBody(email: email, firstName: firstName, lastName: lastName, password: password, role: role)
        )
    }

    func changePassword(userId: Int, newPassword: String) async throws -> APIUser {
        try await updateUser(userId: userId, email: nil, firstName: nil, lastName: nil, password: newPassword, role: nil)
    }
    
    // PUT /api/auth/me - Update current user profile
    func updateMe(email: String?, firstName: String?, lastName: String?, password: String?) async throws -> APIUser {
        struct UpdateMeBody: Encodable {
            let email: String?
            let firstName: String?
            let lastName: String?
            let password: String?
            
            enum CodingKeys: String, CodingKey {
                case email
                case firstName = "first_name"
                case lastName = "last_name"
                case password
            }
            
            // Custom encoding to include null values explicitly
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                // Always encode all fields, using NSNull for nil values to ensure they appear in JSON as null
                if let email = email {
                    try container.encode(email, forKey: .email)
                } else {
                    try container.encodeNil(forKey: .email)
                }
                if let firstName = firstName {
                    try container.encode(firstName, forKey: .firstName)
                } else {
                    try container.encodeNil(forKey: .firstName)
                }
                if let lastName = lastName {
                    try container.encode(lastName, forKey: .lastName)
                } else {
                    try container.encodeNil(forKey: .lastName)
                }
                if let password = password {
                    try container.encode(password, forKey: .password)
                } else {
                    try container.encodeNil(forKey: .password)
                }
            }
        }
        
        return try await api.send(
            .PUT,
            "/api/auth/me",
            body: UpdateMeBody(email: email, firstName: firstName, lastName: lastName, password: password)
        )
    }

    // POST /api/auth/verification-code
    func requestVerificationCode(email: String) async throws {
        struct Body: Encodable { let email: String }
        let _: Empty = try await api.send(.POST, "/api/auth/verification-code", body: Body(email: email))
    }

    // POST /api/auth/verify
    func verifyEmailCode(email: String, code: String) async throws -> APIUser {
        struct Body: Encodable { let email: String; let code: String }
        let res: TokenResponse = try await api.send(.POST, "/api/auth/verify", body: Body(email: email, code: code))
        persistTokens(res)
        return res.user
    }

    // POST /api/auth/login (for both admin and teacher)
    func loginWithPassword(email: String, password: String) async throws -> APIUser {
        struct Body: Encodable { let email: String; let password: String }
        let res: TokenResponse = try await api.send(.POST, "/api/auth/login", body: Body(email: email, password: password))
        persistTokens(res)
        return res.user
    }

    // GET /api/auth/me
    func me() async throws -> APIUser {
        try await api.send(.GET, "/api/auth/me")
    }

    // POST /api/auth/refresh
    @MainActor
    func refresh() async throws -> APIUser {
        struct Body: Encodable { let refresh_token: String }
        guard let rt = AuthStorage.refreshToken else {
            throw APIError(status: 401, message: "No refresh token available")
        }
        let res: TokenResponse = try await api.send(.POST, "/api/auth/refresh", body: Body(refresh_token: rt))
        persistTokens(res)
        return res.user
    }

    // DELETE /api/auth/me - Delete current user account
    func deleteMe() async throws {
        let _: Empty = try await api.send(.DELETE, "/api/auth/me")
        AuthStorage.clear()
    }
    
    // POST /api/auth/logout
    func logout() async throws {
        let _: Empty = try await api.send(.POST, "/api/auth/logout")
        AuthStorage.clear()
    }

    private func persistTokens(_ res: TokenResponse) {
        AuthStorage.accessToken = res.accessToken
        AuthStorage.refreshToken = res.refreshToken
        if let seconds = res.expiresIn {
            AuthStorage.expiresAt = Date().addingTimeInterval(TimeInterval(seconds))
            } else {
                AuthStorage.expiresAt = nil  // or, if you prefer, Date().addingTimeInterval(3600)
            }
    }
}
