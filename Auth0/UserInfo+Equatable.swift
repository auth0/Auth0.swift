//
//  UserInfo+Equatable.swift
//  Auth0
//
//  Created by Kimi on 24/8/21.
//  Copyright © 2021 Auth0. All rights reserved.
//

import Foundation

extension UserInfo {

    // swiftlint:disable:next cyclomatic_complexity
    static func == (lhs: UserInfo, rhs: UserInfo) -> Bool {
        if lhs.sub != rhs.sub { return false }

        if lhs.name != rhs.name { return false }
        if lhs.givenName != rhs.givenName { return false }
        if lhs.familyName != rhs.familyName { return false }
        if lhs.middleName != rhs.middleName { return false }
        if lhs.nickname != rhs.nickname { return false }
        if lhs.preferredUsername != rhs.preferredUsername { return false }

        if lhs.profile != rhs.profile { return false }
        if lhs.picture != rhs.picture { return false }
        if lhs.website != rhs.website { return false }

        if lhs.email != rhs.email { return false }
        if lhs.emailVerified != rhs.emailVerified { return false }

        if lhs.gender != rhs.gender { return false }
        if lhs.birthdate != rhs.birthdate { return false }

        if lhs.zoneinfo != rhs.zoneinfo { return false }
        if lhs.locale != rhs.locale { return false }

        if lhs.phoneNumber != rhs.phoneNumber { return false }
        if lhs.phoneNumberVerified != rhs.phoneNumberVerified { return false }
        if lhs.address != rhs.address { return false }

        if lhs.updatedAt != rhs.updatedAt { return false }

        let lhsCustomClaims = lhs.customClaims ?? [String: AnyCodable]()
        let rhsCustomClaims = rhs.customClaims ?? [String: AnyCodable]()

        if lhsCustomClaims.count != rhsCustomClaims.count { return false }
        for key in lhsCustomClaims.keys {
            let lhsValue = lhsCustomClaims[key] as? AnyHashable
            let rhsValue = rhsCustomClaims[key] as? AnyHashable
            if lhsValue != rhsValue { return false }
        }

        return true
    }

    static func == (lhs: UserInfo, rhs: UserInfo?) -> Bool {
        guard let rhs = rhs else { return false }
        return lhs == rhs
    }

    static func == (lhs: UserInfo?, rhs: UserInfo) -> Bool {
        guard let lhs = lhs else { return false }
        return lhs == rhs
    }
}
