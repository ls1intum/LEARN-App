//
//  LossyString.swift
//  Master
//
//  Created by Minkyoung Park on 24.09.25.
//

import Foundation

/// Decodes String from `"abc"`, 123, 123.0, true/false, or null. Returns `nil` if it can't parse.
struct LossyString: Decodable {
    let value: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { value = nil; return }
        if let s = try? c.decode(String.self)   { value = s; return }
        if let i = try? c.decode(Int.self)      { value = String(i); return }
        if let d = try? c.decode(Double.self)   { value = String(d); return }
        if let b = try? c.decode(Bool.self)     { value = b ? "true" : "false"; return }
        value = nil
    }
}
