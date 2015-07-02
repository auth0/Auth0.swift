//  A0UsersSpec.m
//
// Copyright (c) 2014 Auth0 (http://auth0.com)
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

#define QUICK_DISABLE_SHORT_SYNTAX 1

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>
@import Auth0;
@import OHHTTPStubs;

QuickSpecBegin(UsersSpec)

Auth0API *api = [[Auth0API alloc] initWithDomain:@"https://samples.auth0.com" token:@"token"];
NSString *userId = @"auth01234567890";

beforeEach(^{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest* request) { return YES; }
                        withStubResponse:^OHHTTPStubsResponse*(NSURLRequest* request) {
                            return [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:@"com.auth0.ios" code:-1 userInfo:nil]];
                        }];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest* request) { return [request.URL.path hasPrefix:@"/api/v2/users"]; }
                        withStubResponse:^OHHTTPStubsResponse*(NSURLRequest* request) {
                            return [OHHTTPStubsResponse responseWithJSONObject:@{@"user_id": userId} statusCode:200 headers:@{@"Content-Type": @"application/json"}];
                        }];
});

afterEach(^{
    [OHHTTPStubs removeAllStubs];
});

it(@"should update user", ^{
    waitUntil(^(void (^done)(void)){
        [api updateUser:userId parameters:@{@"key": @"value"} callback:^(NSError * error, NSDictionary * payload) {
            expect(error).to(beNil());
            expect(payload).to(equal(@{@"user_id": userId}));
            done();
        }];
    });
});

it(@"should find a user", ^{
    waitUntil(^(void (^done)(void)){
        [api findUser:userId fields:@[@"user_id", @"email"] includeFields:YES callback:^(NSError * error, NSDictionary * payload) {
            expect(error).to(beNil());
            expect(payload).to(equal(@{@"user_id": userId}));
            done();
        }];
    });
});

QuickSpecEnd