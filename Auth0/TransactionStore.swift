// TransactionStore.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#if WEB_AUTH_PLATFORM
import Foundation

/// Keeps track of current Auth Transaction
class TransactionStore {

    static let shared = TransactionStore()

    private(set) var current: AuthTransaction?

    func resume(_ url: URL) -> Bool {
        let resumed = self.current?.resume(url) ?? false
        if resumed {
            self.current = nil
        }
        return resumed
    }

    func store(_ transaction: AuthTransaction) {
        self.current?.cancel()
        self.current = transaction
    }

    func cancel(_ transaction: AuthTransaction) {
        transaction.cancel()
        if self.current?.state == transaction.state {
            self.current = nil
        }
    }

    func clear() {
        self.current = nil
    }

}
#endif
