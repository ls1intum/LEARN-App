//
//  LossyDouble.swift
//  Master
//
//  Created by Minkyoung Park on 25.09.25.
//

import Foundation

// Lossy number that accepts Int, Double, "123", null
struct LossyDouble: Decodable {
    let value: Double?

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { value = nil; return }
        if let d = try? c.decode(Double.self) { value = d; return }
        if let i = try? c.decode(Int.self)    { value = Double(i); return }
        if let s = try? c.decode(String.self) {
            value = Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
            return
        }
        value = nil
    }
}
