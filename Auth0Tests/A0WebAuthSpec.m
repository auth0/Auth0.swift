// A0WebAuthSpec.m
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

#define QUICK_DISABLE_SHORT_SYNTAX 1

@import Quick;
@import Nimble;

@import Auth0;

QuickSpecBegin(A0WebAuthSpec)

NSString *clientId = @"MyClientId";
NSURL *domain = [NSURL URLWithString:@"https://samples.auth0.com"];

describe(@"init", ^{
    it(@"should create component", ^{
        A0WebAuth *webAuth = [[A0WebAuth alloc] initWithClientId:clientId url:domain];
        expect(webAuth).toNot(beNil());
    });

    it(@"should not have connection", ^{
        A0WebAuth *webAuth = [[A0WebAuth alloc] initWithClientId:clientId url:domain];
        expect(webAuth.connection).to(beNil());
    });
    
    it(@"should not have scope", ^{
        A0WebAuth *webAuth = [[A0WebAuth alloc] initWithClientId:clientId url:domain];
        expect(webAuth.scope).to(beNil());
    });

    it(@"should not use universal links", ^{
        A0WebAuth *webAuth = [[A0WebAuth alloc] initWithClientId:clientId url:domain];
        expect(@(webAuth.universalLink)).to(beFalsy());
    });

    it(@"should not use an ephemeral session", ^{
        A0WebAuth *webAuth = [[A0WebAuth alloc] initWithClientId:clientId url:domain];
        expect(@(webAuth.ephemeralSession)).to(beFalsy());
    });
});

describe(@"options", ^{

    __block A0WebAuth *webAuth;

    beforeEach(^{
        webAuth = [[A0WebAuth alloc] initWithClientId:clientId url:domain];
    });

    it(@"should add parameters", ^{
        NSDictionary *parameters = @{@"key" : @"value"};
        [webAuth addParameters: parameters];
    });

    it(@"should set universal link flag", ^{
        webAuth.universalLink = YES;
        expect(@(webAuth.universalLink)).to(beTruthy());
    });
    
    it(@"should set ephemeral session flag", ^{
        webAuth.ephemeralSession = YES;
        expect(@(webAuth.ephemeralSession)).to(beTruthy());
    });

    it(@"should set connection", ^{
        webAuth.connection = @"connection";
        expect(webAuth.connection).to(equal(@"connection"));
    });

    it(@"should set connection if is non-nil", ^{
        webAuth.connection = @"connection";
        webAuth.connection = nil;
        expect(webAuth.connection).to(equal(@"connection"));
    });

    it(@"should set scope", ^{
        webAuth.scope = @"openid";
        expect(webAuth.scope).to(equal(@"openid"));
    });

    it(@"should set connection if is non-nil", ^{
        webAuth.scope = @"openid";
        webAuth.scope = nil;
        expect(webAuth.scope).to(equal(@"openid"));
    });

});
QuickSpecEnd
