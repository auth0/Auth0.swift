//
//  AnyCodable+Hashable.swift
//  Auth0
//
//  Created by Kimi on 20/8/21.
//  Copyright © 2021 Auth0. All rights reserved.
//

import Foundation

extension AnyCodable: Hashable {

    // swiftlint:disable:next cyclomatic_complexity
    public func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool:
            hasher.combine(value)
        case let value as Int:
            hasher.combine(value)
        case let value as Int8:
            hasher.combine(value)
        case let value as Int16:
            hasher.combine(value)
        case let value as Int32:
            hasher.combine(value)
        case let value as Int64:
            hasher.combine(value)
        case let value as UInt:
            hasher.combine(value)
        case let value as UInt8:
            hasher.combine(value)
        case let value as UInt16:
            hasher.combine(value)
        case let value as UInt32:
            hasher.combine(value)
        case let value as UInt64:
            hasher.combine(value)
        case let value as Float:
            hasher.combine(value)
        case let value as Double:
            hasher.combine(value)
        case let value as String:
            hasher.combine(value)
        case let value as [String: AnyCodable]:
            hasher.combine(value)
        case let value as [AnyCodable]:
            hasher.combine(value)
        default:
            break
        }
    }

    public var hashValue: Int {
        get {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }
}
