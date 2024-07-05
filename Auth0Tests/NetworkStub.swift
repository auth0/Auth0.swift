//
//  NetworkStub.swift
//  Auth0
//
//  Created by Desu Sai Venkat on 26/06/24.
//  Copyright © 2024 Auth0. All rights reserved.
//

import Foundation

typealias RequestCondition = (URLRequest) -> Bool
typealias RequestResponse = (URLRequest) -> (Data?, URLResponse?, Error?)

struct NetworkStub {
    static private(set) var stubs: [(condition: RequestCondition, response: RequestResponse)] = []

    static func addStub(condition: @escaping RequestCondition, response: @escaping RequestResponse) {
        stubs.append((condition, response))
    }

    static func clearStubs() {
        stubs.removeAll()
    }
}
