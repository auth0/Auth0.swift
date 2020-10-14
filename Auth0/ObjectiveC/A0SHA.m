// A0SHA.m
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
#import "A0SHA.h"
#import <CommonCrypto/CommonHMAC.h>

static NSString * const kDefaultSHAAlgorithm = @"sha256";

@interface A0SHA ()
@property (readonly, nonatomic) NSInteger digestLength;
@end

@implementation A0SHA

- (instancetype)initWithAlgorithm:(NSString *)algorithm {
    self = [super init];
    if (self) {
        const NSString * alg = algorithm.lowercaseString;
        if ([kDefaultSHAAlgorithm  isEqual: alg]) {
            _digestLength = CC_SHA256_DIGEST_LENGTH;
        } else {
            return nil;
        }
    }
    return self;
}

- (instancetype)init {
    return [self initWithAlgorithm: kDefaultSHAAlgorithm];
}

- (NSData *)hash:(NSData *)data {
    uint8_t hashBytes[self.digestLength];
    memset(hashBytes, 0x0, self.digestLength);

    CC_SHA256(data.bytes, (CC_LONG)data.length, hashBytes);

    NSData *hash = [NSData dataWithBytes:hashBytes length:self.digestLength];
    return hash;
}

@end
#endif
