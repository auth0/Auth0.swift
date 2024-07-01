//
//  StubURLProtocol.swift
//  Auth0
//
//  Created by Desu Sai Venkat on 26/06/24.
//  Copyright © 2024 Auth0. All rights reserved.
//

import Foundation

class StubURLProtocol: URLProtocol {
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return NetworkStub.stubs.contains { $0.condition(request) }
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let stub = NetworkStub.stubs.first(where: { $0.condition(request) }) {
            let (data, response, error) = stub.response(request)
            if let error = error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                if let response = response {
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let data = data {
                    client?.urlProtocol(self, didLoad: data)
                }
                client?.urlProtocolDidFinishLoading(self)
            }
        }
    }
    
    override func stopLoading() {
        dataTask?.cancel()
        session = nil
        dataTask = nil
    }
}

