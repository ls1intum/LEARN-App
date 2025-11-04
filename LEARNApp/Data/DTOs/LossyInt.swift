//
//  LossyInt.swift
//  Master
//
//  Created by Minkyoung Park on 24.09.25.
//

import Foundation

/// Decodes Int from `Int`, `"123"`, or `null`. Returns `nil` if it can't parse.
struct LossyInt: Decodable {
    let value: Int?

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { value = nil; return }
        if let i = try? c.decode(Int.self) { value = i; return }
        if let s = try? c.decode(String.self) {
            value = Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
            return
        }
        // Unknown type (e.g., object) → treat as missing instead of failing
        value = nil
    }
}
