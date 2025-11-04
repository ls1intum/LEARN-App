//
//  FavoritesManager.swift
//  MasterApp
//
//  Created by Minkyoung Park on 14.07.25.
//

import Foundation

class FavoritesManager {
    private static func key(for email: String) -> String {
        return "favoriteMaterialIDs_\(email.lowercased())"
    }

    static func saveFavorites(_ ids: [UUID], for email: String) {
        let strings = ids.map { $0.uuidString }
        UserDefaults.standard.set(strings, forKey: key(for: email))
    }

    static func loadFavorites(for email: String) -> [UUID] {
        let strings = UserDefaults.standard.stringArray(forKey: key(for: email)) ?? []
        return strings.compactMap { UUID(uuidString: $0) }
    }
}
