//
//  AuthStorage.swift
//  Master
//
//  Created by Minkyoung Park on 23.09.25.
//

import Foundation

enum AuthStorage {
    private static let kAccess  = "auth_access_token"
    private static let kRefresh = "auth_refresh_token"
    private static let kExpiry  = "auth_expires_at"

    static var accessToken: String? {
        get { UserDefaults.standard.string(forKey: kAccess) }
        set { UserDefaults.standard.setValue(newValue, forKey: kAccess) }
    }

    static var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: kRefresh) }
        set { UserDefaults.standard.setValue(newValue, forKey: kRefresh) }
    }

    static var expiresAt: Date? {
        get { UserDefaults.standard.object(forKey: kExpiry) as? Date }
        set { UserDefaults.standard.setValue(newValue, forKey: kExpiry) }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: kAccess)
        UserDefaults.standard.removeObject(forKey: kRefresh)
        UserDefaults.standard.removeObject(forKey: kExpiry)
    }
}
