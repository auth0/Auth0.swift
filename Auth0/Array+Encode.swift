// Array+Encode.swift
//
// Copyright (c) 2019 Auth0 (http://auth0.com)
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

extension Array where Element == UInt8 {
    func a0_derEncode(as dataType: UInt8) -> [UInt8] {
        var encodedBytes: [UInt8] = [dataType]
        var numberOfBytes = count
        if numberOfBytes < 128 {
            encodedBytes.append(UInt8(numberOfBytes))
        } else {
            let lengthData = Data(bytes: &numberOfBytes, count: MemoryLayout.size(ofValue: numberOfBytes))
            let lengthBytes = [UInt8](lengthData).filter({ $0 != 0 }).reversed()
            encodedBytes.append(UInt8(truncatingIfNeeded: lengthBytes.count) | 0b10000000)
            encodedBytes.append(contentsOf: lengthBytes)
        }
        encodedBytes.append(contentsOf: self)
        return encodedBytes
    }
}
#endif
