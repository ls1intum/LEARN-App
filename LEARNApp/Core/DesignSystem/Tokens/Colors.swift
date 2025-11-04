//
//  Colors.swift
//  Master
//
//  Created by Minkyoung Park on 15.09.25.
//

import SwiftUI

enum AppColors {
    // Buttons (legacy filled button)
    static let primary      = Color(red: 96/255, green: 165/255, blue: 250/255) // #60A5FA

    // Blue used for the device pill text and the filled heart
    static let primaryDark  = Color(red: 59/255, green: 130/255, blue: 246/255) // #3B82F6

    // Device pill background
    static let tagBG        = Color(red: 226/255, green: 240/255, blue: 255/255) // #E2F0FF

    // Card background
    static let cardBG       = Color(red: 248/255, green: 250/255, blue: 255/255) // #F8FAFF

    // Title text in card
    static let title        = Color(red: 26/255, green: 12/255, blue: 87/255)    // #1A0C57

    // Muted meta text
    static let textMuted    = Color(red: 92/255, green: 92/255, blue: 92/255)    // #5C5C5C

    static let border       = Color.gray.opacity(0.35)

    // Disabled state
    static let disabledFill = Color(red: 157/255, green: 157/255, blue: 157/255) // #9D9D9D
}
