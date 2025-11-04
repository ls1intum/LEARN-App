//
//  FavoritesStore.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import Foundation

enum FavoritesStore {
    private static func key(for email: String) -> String {
        "favoriteMaterialIDs_\(email.lowercased())"
    }

    static func load(for email: String) -> [Int] {
        UserDefaults.standard.array(forKey: key(for: email)) as? [Int] ?? []
    }

    static func save(_ ids: [Int], for email: String) {
        UserDefaults.standard.set(ids, forKey: key(for: email))
    }

    static func toggle(id: Int, for email: String) {
        var ids = load(for: email)
        if let i = ids.firstIndex(of: id) { ids.remove(at: i) } else { ids.append(id) }
        save(ids, for: email)
    }
}
