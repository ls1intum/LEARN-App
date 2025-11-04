//
//  APIClient.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import Foundation

enum HTTPMethod: String { case GET, POST, PUT, PATCH, DELETE }

struct APIError: Error, LocalizedError {
    let status: Int
    let message: String
    var errorDescription: String? { message }
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: () -> String?

    init(baseURL: URL = Config.apiBaseURL,
         session: URLSession = .shared,
         tokenProvider: @escaping () -> String? = { AuthStorage.accessToken }) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
    }

    // ---- NO-BODY OVERLOAD ----
    func send<T: Decodable>(_ method: HTTPMethod,
                            _ path: String,
                            query: [URLQueryItem] = [],
                            decoder: JSONDecoder = .init()) async throws -> T {
        let req = try makeRequest(method, path, query: query)
        return try await perform(req, decoder: decoder)
    }

    // ---- BODY OVERLOAD ----
    func send<T: Decodable, B: Encodable>(_ method: HTTPMethod,
                                          _ path: String,
                                          body: B,
                                          query: [URLQueryItem] = [],
                                          decoder: JSONDecoder = .init()) async throws -> T {
        var req = try makeRequest(method, path, query: query)
        req.httpBody = try JSONEncoder().encode(body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await perform(req, decoder: decoder)
    }
    
    // ---- BINARY RESPONSE OVERLOAD ----
    func sendBinary<B: Encodable>(_ method: HTTPMethod,
                                 _ path: String,
                                 body: B,
                                 query: [URLQueryItem] = []) async throws -> Data {
        var req = try makeRequest(method, path, query: query)
        req.httpBody = try JSONEncoder().encode(body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await performBinary(req)
    }

    // MARK: - Internals

    private func makeRequest(_ method: HTTPMethod,
                             _ path: String,
                             query: [URLQueryItem]) throws -> URLRequest {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            // Werte sicher encodieren (keine & / = in Values)
            let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+"))
            let parts = query.compactMap { item -> String? in
                guard let v = item.value else { return nil }
                let name = item.name.addingPercentEncoding(withAllowedCharacters: allowed) ?? item.name
                let value = v.addingPercentEncoding(withAllowedCharacters: allowed) ?? v
                return "\(name)=\(value)"
            }
            comps.percentEncodedQuery = parts.joined(separator: "&")
        }
        guard let url = comps.url else { throw APIError(status: -1, message: "Bad URL") }

        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = tokenProvider() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func perform<T: Decodable>(_ req: URLRequest,
                                       decoder: JSONDecoder) async throws -> T {
        print("➡️", req.httpMethod ?? "", req.url?.absoluteString ?? "")
        print("   Auth header present:", req.value(forHTTPHeaderField: "Authorization") != nil)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError(status: -1, message: "No HTTP response")
        }

        if (200..<300).contains(http.statusCode) {
            if T.self == Empty.self { return Empty() as! T }

            let dec = decoder
            dec.keyDecodingStrategy = .convertFromSnakeCase

            // 👇 robust ISO8601 (with and without fractional seconds)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let isoNoFrac = ISO8601DateFormatter()
            isoNoFrac.formatOptions = [.withInternetDateTime]

            // robust ISO8601 decoding (with + without fractional seconds) without capturing non-Sendable state
            dec.dateDecodingStrategy = .custom { decoder in
                let c = try decoder.singleValueContainer()
                let s = try c.decode(String.self)

                // ISO 8601 (with & without fractional seconds)
                let isoWithFrac = ISO8601DateFormatter()
                isoWithFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                isoWithFrac.timeZone = TimeZone(secondsFromGMT: 0)

                let isoNoFrac = ISO8601DateFormatter()
                isoNoFrac.formatOptions = [.withInternetDateTime]
                isoNoFrac.timeZone = TimeZone(secondsFromGMT: 0)

                if let dt = isoWithFrac.date(from: s) ?? isoNoFrac.date(from: s) {
                    return dt
                }

                // RFC 1123 (e.g., "Tue, 07 Oct 2025 09:25:22 GMT")
                let rfc1123 = DateFormatter()
                rfc1123.locale = Locale(identifier: "en_US_POSIX")
                rfc1123.timeZone = TimeZone(secondsFromGMT: 0)
                rfc1123.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"

                if let dt = rfc1123.date(from: s) {
                    return dt
                }

                throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unrecognized date format: \(s)")
            }


            do {
                return try dec.decode(T.self, from: data)
            } catch {
                // helpful logging while you integrate
                print("Decoding failed:", error)
                print("Server JSON:", String(data: data, encoding: .utf8) ?? "<non-utf8>")
                throw error
            }
        } else if http.statusCode == 204, T.self == Empty.self {
            return Empty() as! T
        } else {
            // Build a useful message from the body
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            var msg = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)

            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let m = obj["message"] as? String { msg = m }
                else if let d = obj["detail"] as? String { msg = d }
                else if let error = obj["error"] as? String { msg = error }
                else if let errors = obj["errors"] as? [String: Any] {
                    // pick the first field error if present
                    let first = errors.values.first
                    if let arr = first as? [String], let firstMsg = arr.first { msg = firstMsg }
                    else { msg = "\(errors)" }
                }
            }
            print("❌ HTTP \(http.statusCode) – \(req.httpMethod ?? "") \(req.url?.absoluteString ?? "")")
            print("↩︎ Body:", bodyString)

            throw APIError(status: http.statusCode, message: msg)
        }

    }
    
    private func performBinary(_ req: URLRequest) async throws -> Data {
        print("➡️", req.httpMethod ?? "", req.url?.absoluteString ?? "")
        print("   Auth header present:", req.value(forHTTPHeaderField: "Authorization") != nil)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError(status: -1, message: "No HTTP response")
        }

        if (200..<300).contains(http.statusCode) {
            return data
        } else {
            // Build a useful message from the body
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            var msg = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)

            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let m = obj["message"] as? String { msg = m }
                else if let d = obj["detail"] as? String { msg = d }
                else if let error = obj["error"] as? String { msg = error }
                else if let errors = obj["errors"] as? [String: Any] {
                    // pick the first field error if present
                    let first = errors.values.first
                    if let arr = first as? [String], let firstMsg = arr.first { msg = firstMsg }
                    else { msg = "\(errors)" }
                }
            }
            print("❌ HTTP \(http.statusCode) – \(req.httpMethod ?? "") \(req.url?.absoluteString ?? "")")
            print("↩︎ Body:", bodyString)

            throw APIError(status: http.statusCode, message: msg)
        }
    }

}

struct Empty: Decodable {}
