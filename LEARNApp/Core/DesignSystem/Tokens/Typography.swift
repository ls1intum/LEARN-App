//
//  Typography.swift
//  Master
//
//  Created by Minkyoung Park on 15.09.25.
//

import SwiftUI

enum Typography {
    // Titles
    static let titleXL = Font.system(size: 28, weight: .bold, design: .rounded)
    static let titleL  = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let titleM  = Font.system(size: 20, weight: .semibold, design: .rounded)

    // Body
    static let bodyL   = Font.system(size: 17, weight: .regular, design: .rounded)
    static let body    = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodyB   = Font.system(size: 15, weight: .semibold, design: .rounded)

    // Meta
    static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
}
