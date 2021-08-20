// AnyCodable.swift
//
// Based on https://github.com/Flight-School/AnyCodable
// with modifications to support URL

/**
 A type-erased `Codable` value.

 The `AnyCodable` type forwards encoding and decoding responsibilities
 to an underlying value, hiding its specific underlying type.

 You can encode or decode mixed-type values in dictionaries
 and other collections that require `Encodable` or `Decodable` conformance
 by declaring their contained type to be `AnyCodable`.

 - SeeAlso: `AnyEncodable`
 - SeeAlso: `AnyDecodable`
 */
@frozen public struct AnyCodable: Codable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

extension AnyCodable: _AnyEncodable, _AnyDecodable {}

extension AnyCodable: ExpressibleByNilLiteral {}
extension AnyCodable: ExpressibleByBooleanLiteral {}
extension AnyCodable: ExpressibleByIntegerLiteral {}
extension AnyCodable: ExpressibleByFloatLiteral {}
extension AnyCodable: ExpressibleByStringLiteral {}
extension AnyCodable: ExpressibleByArrayLiteral {}
extension AnyCodable: ExpressibleByDictionaryLiteral {}
