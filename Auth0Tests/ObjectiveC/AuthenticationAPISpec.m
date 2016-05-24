// AuthenticationAPISpec.m
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
@import OHHTTPStubs;
@import Auth0;

QuickSpecBegin(AuthenticationAPISpec)

NSString *clientId = @"MyClientId";
NSURL *domain = [NSURL a0_URLWithDomain:@"samples.auth0.com"];
NSString *token = @"A TOKEN";
NSString *bearer = @"bearer";

beforeEach(^{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:@"com.auth0" code:-9999999 userInfo:nil]];
    }];
});

afterEach(^{
    [OHHTTPStubs removeAllStubs];
});

describe(@"init", ^{

    it(@"should build with clientId and domain URL", ^{
        A0AuthenticationAPI *api = [[A0AuthenticationAPI alloc] initWithClientId:@"ClientID" url:[NSURL URLWithString:@"https://samples.auth0.com"]];
        expect(api).toNot(beNil());
    });

    it(@"should build with clientId, domain URL and a NSURLSession", ^{
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        A0AuthenticationAPI *api = [[A0AuthenticationAPI alloc] initWithClientId:@"ClientID" url:[NSURL URLWithString:@"https://samples.auth0.com"] session:session];
        expect(api).toNot(beNil());
    });

});

describe(@"login", ^{

    __block A0AuthenticationAPI *api;

    beforeEach(^{
        api = [[A0AuthenticationAPI alloc] initWithClientId:clientId url:domain];
    });

    it(@"should authenticate", ^{
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:domain.host] && [request.URL.path isEqualToString:@"/oauth/ro"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{@"access_token": token, @"token_type": bearer}
                                                    statusCode:200
                                                       headers:@{@"Content-Type":@"application/json"}];
        }];

        waitUntilTimeout(3000, ^(void(^done)()) {
            [api loginWithUsername:@"support@auth0.com"
                          password:@"random password"
                        connection:@"Username-Password-Authentication"
                             scope:@"openid"
                        parameters:nil
                          callback:^(NSError * _Nullable error, A0Credentials * _Nullable credentials) {
                              expect(credentials.accessToken).to(equal(token));
                              expect(credentials.tokenType).to(equal(bearer));
                              expect(error).to(beNil());
                              done();
                          }];
        });
    });

    it(@"should handle error", ^{
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:domain.host] && [request.URL.path isEqualToString:@"/oauth/ro"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{@"error": @"invalid_username_password", @"error_description": @"invalid password"}
                                                    statusCode:401
                                                       headers:@{@"Content-Type":@"application/json"}];
        }];

        waitUntilTimeout(3000, ^(void(^done)()) {
            [api loginWithUsername:@"support@auth0.com"
                          password:@"random password"
                        connection:@"Username-Password-Authentication"
                             scope:@"openid"
                        parameters:nil
                          callback:^(NSError * _Nullable error, A0Credentials * _Nullable credentials) {
                              expect(credentials).to(beNil());
                              expect(error).toNot(beNil());
                              expect(error.domain).to(equal(@"com.auth0.authentication"));
                              expect(@(error.code)).to(equal(@(A0AuthenticationErrorCodeErrorResponse)));
                              expect(error.a0_authenticationErrorCode).to(equal(@"invalid_username_password"));
                              expect(error.a0_authenticationErrorDescription).to(equal(@"invalid password"));
                              done();
                          }];
        });
    });

});

describe(@"create user", ^{

    __block A0AuthenticationAPI *api;

    beforeEach(^{
        api = [[A0AuthenticationAPI alloc] initWithClientId:clientId url:domain];
    });

    it(@"should create user", ^{
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:domain.host] && [request.URL.path isEqualToString:@"/dbconnections/signup"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{@"email": @"support@auth0.com", @"email_verified": @"true"}
                                                    statusCode:200
                                                       headers:@{@"Content-Type":@"application/json"}];
        }];

        waitUntilTimeout(3000, ^(void(^done)()) {
            [api createUserWithEmail:@"support@auth0.com"
                            username:nil
                            password:@"random pass"
                          connection:@"MyConnection"
                        userMetadata:nil
                            callback:^(NSError * _Nullable error, NSDictionary<NSString *,id> * _Nullable databaseUser) {
                                expect(databaseUser[@"email"]).to(equal(@"support@auth0.com"));
                                expect(error).to(beNil());
                                done();
                            }];
        });
    });

    it(@"should handle error", ^{
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:domain.host] && [request.URL.path isEqualToString:@"/dbconnections/signup"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{@"error": @"invalid_username_password", @"error_description": @"invalid password"}
                                                    statusCode:401
                                                       headers:@{@"Content-Type":@"application/json"}];
        }];

        waitUntilTimeout(3000, ^(void(^done)()) {
            [api createUserWithEmail:@"support@auth0.com"
                            username:nil
                            password:@"random pass"
                          connection:@"MyConnection"
                        userMetadata:nil
                            callback:^(NSError * _Nullable error, NSDictionary<NSString *,id> * _Nullable databaseUser) {
                                expect(databaseUser).to(beNil());
                                expect(error).toNot(beNil());
                                expect(error.domain).to(equal(@"com.auth0.authentication"));
                                expect(@(error.code)).to(equal(@(A0AuthenticationErrorCodeErrorResponse)));
                                expect(error.a0_authenticationErrorCode).to(equal(@"invalid_username_password"));
                                expect(error.a0_authenticationErrorDescription).to(equal(@"invalid password"));
                                done();
                            }];
        });
    });
    
});

describe(@"reset password", ^{

    __block A0AuthenticationAPI *api;

    beforeEach(^{
        api = [[A0AuthenticationAPI alloc] initWithClientId:clientId url:domain];
    });

    it(@"should request change password", ^{
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:domain.host] && [request.URL.path isEqualToString:@"/dbconnections/change_password"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{}
                                                    statusCode:204
                                                       headers:@{@"Content-Type":@"application/json"}];
        }];

        waitUntilTimeout(3000, ^(void(^done)()) {
            [api resetPasswordWithEmail:@"support@auth0.com"
                             connection:@"MyConnection"
                               callback:^(NSError * _Nullable error) {
                                   expect(error).to(beNil());
                                   done();
                               }];
        });
    });

    it(@"should handle error", ^{
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:domain.host] && [request.URL.path isEqualToString:@"/dbconnections/change_password"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{@"error": @"invalid_username_password", @"error_description": @"invalid password"}
                                                    statusCode:401
                                                       headers:@{@"Content-Type":@"application/json"}];
        }];

        waitUntilTimeout(3000, ^(void(^done)()) {
            [api resetPasswordWithEmail:@"support@auth0.com"
                             connection:@"MyConnection"
                               callback:^(NSError * _Nullable error) {
                                   expect(error).toNot(beNil());
                                   expect(error.domain).to(equal(@"com.auth0.authentication"));
                                   expect(@(error.code)).to(equal(@(A0AuthenticationErrorCodeErrorResponse)));
                                   expect(error.a0_authenticationErrorCode).to(equal(@"invalid_username_password"));
                                   expect(error.a0_authenticationErrorDescription).to(equal(@"invalid password"));
                                   done();
                               }];
        });
    });

});

describe(@"signup", ^{

    __block A0AuthenticationAPI *api;

    beforeEach(^{
        api = [[A0AuthenticationAPI alloc] initWithClientId:clientId url:domain];
    });

    it(@"should authenticate", ^{
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:domain.host] && [request.URL.path isEqualToString:@"/dbconnections/signup"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{@"email": @"support@auth0.com", @"email_verified": @"true"}
                                                    statusCode:200
                                                       headers:@{@"Content-Type":@"application/json"}];
        }];
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:domain.host] && [request.URL.path isEqualToString:@"/oauth/ro"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{@"access_token": token, @"token_type": bearer}
                                                    statusCode:200
                                                       headers:@{@"Content-Type":@"application/json"}];
        }];

        waitUntilTimeout(3000, ^(void(^done)()) {
            [api signUpWithEmail:@"support@auth0.com"
                        username:nil
                        password:@"random password"
                      connection:@"Username-Password-Authentication"
                    userMetadata: nil
                           scope:@"openid"
                      parameters:nil
                          callback:^(NSError * _Nullable error, A0Credentials * _Nullable credentials) {
                              expect(credentials.accessToken).to(equal(token));
                              expect(credentials.tokenType).to(equal(bearer));
                              expect(error).to(beNil());
                              done();
                          }];
        });
    });

    it(@"should handle error", ^{
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.host isEqualToString:domain.host] && [request.URL.path isEqualToString:@"/dbconnections/signup"];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:@{@"error": @"invalid_username_password", @"error_description": @"invalid password"}
                                                    statusCode:401
                                                       headers:@{@"Content-Type":@"application/json"}];
        }];

        waitUntilTimeout(3000, ^(void(^done)()) {
            [api signUpWithEmail:@"support@auth0.com"
                        username:nil
                        password:@"random password"
                      connection:@"Username-Password-Authentication"
                    userMetadata: nil
                           scope:@"openid"
                      parameters:nil
                        callback:^(NSError * _Nullable error, A0Credentials * _Nullable credentials) {
                            expect(credentials).to(beNil());
                            expect(error).toNot(beNil());
                            expect(error.domain).to(equal(@"com.auth0.authentication"));
                            expect(@(error.code)).to(equal(@(A0AuthenticationErrorCodeErrorResponse)));
                            expect(error.a0_authenticationErrorCode).to(equal(@"invalid_username_password"));
                            expect(error.a0_authenticationErrorDescription).to(equal(@"invalid password"));
                            done();
                        }];
        });
    });
    
});
QuickSpecEnd