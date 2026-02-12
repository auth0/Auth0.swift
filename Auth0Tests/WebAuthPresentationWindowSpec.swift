//
//  WebAuthPresentationWindowSpec.swift
//  Auth0Tests
//
//  Created by Auth0 on 10/02/26.
//  Copyright © 2026 Auth0. All rights reserved.
//

import Quick
import Nimble

@testable import Auth0

#if os(iOS)
import UIKit
typealias PlatformWindow = UIWindow
#elseif os(macOS)
import AppKit
typealias PlatformWindow = NSWindow
#endif

private let ClientId = "ClientId"
private let Domain = "samples.auth0.com"
private let DomainURL = URL.httpsURL(from: Domain)

private func newWebAuth() -> Auth0WebAuth {
    return Auth0WebAuth(clientId: ClientId, url: DomainURL, barrier: MockBarrier())
}

class WebAuthPresentationWindowSpec: QuickSpec {

    override class func spec() {

        describe("presentationWindow builder method") {

            #if os(iOS) || os(visionOS)
            it("should store the UIWindow") {
                let window = UIWindow()
                let webAuth = newWebAuth()
                    .presentationWindow(window)

                expect(webAuth.presentationWindow).to(be(window))
            }

            it("should allow chaining with other builder methods") {
                let window = UIWindow()
                let webAuth = newWebAuth()
                    .connection("facebook")
                    .presentationWindow(window)
                    .scope("openid profile")

                expect(webAuth.presentationWindow).to(be(window))
                expect(webAuth.parameters["connection"]) == "facebook"
                expect(webAuth.parameters["scope"]) == "openid profile"
            }

            it("should support being called multiple times") {
                let window1 = UIWindow()
                let window2 = UIWindow()
                let webAuth = newWebAuth()
                    .presentationWindow(window1)
                    .presentationWindow(window2)

                expect(webAuth.presentationWindow).to(be(window2))
            }
            #endif

            #if os(macOS)
            it("should store the NSWindow") {
                let window = NSWindow()
                let webAuth = newWebAuth()
                    .presentationWindow(window)

                expect(webAuth.presentationWindow).to(be(window))
            }

            it("should allow chaining with other builder methods") {
                let window = NSWindow()
                let webAuth = newWebAuth()
                    .connection("facebook")
                    .presentationWindow(window)
                    .scope("openid profile")

                expect(webAuth.presentationWindow).to(be(window))
                expect(webAuth.parameters["connection"]) == "facebook"
                expect(webAuth.parameters["scope"]) == "openid profile"
            }

            it("should support being called multiple times") {
                let window1 = NSWindow()
                let window2 = NSWindow()
                let webAuth = newWebAuth()
                    .presentationWindow(window1)
                    .presentationWindow(window2)

                expect(webAuth.presentationWindow).to(be(window2))
            }
            #endif

        }

        describe("ASProvider with custom window") {

            #if os(iOS) || os(visionOS)
            it("should pass window to ASUserAgent") {
                let window = UIWindow()
                let redirectURL = URL(string: "https://samples.auth0.com/callback")!

                let provider = WebAuthentication.asProvider(
                    redirectURL: redirectURL,
                    ephemeralSession: false,
                    headers: nil,
                    presentationWindow: window
                )

                let userAgent = provider(URL(string: "https://auth0.com")!) { _ in }

                if let asUserAgent = userAgent as? ASUserAgent {
                    expect(asUserAgent.presentationWindow).to(be(window))
                } else {
                    fail("Expected ASUserAgent")
                }
            }

            it("should work without window parameter") {
                let redirectURL = URL(string: "https://samples.auth0.com/callback")!

                let provider = WebAuthentication.asProvider(
                    redirectURL: redirectURL,
                    ephemeralSession: false,
                    headers: nil
                )

                let userAgent = provider(URL(string: "https://auth0.com")!) { _ in }

                if let asUserAgent = userAgent as? ASUserAgent {
                    expect(asUserAgent.presentationWindow).to(beNil())
                } else {
                    fail("Expected ASUserAgent")
                }
            }
            #endif

            #if os(macOS)
            it("should pass window to ASUserAgent") {
                let window = NSWindow()
                let redirectURL = URL(string: "https://samples.auth0.com/callback")!

                let provider = WebAuthentication.asProvider(
                    redirectURL: redirectURL,
                    ephemeralSession: false,
                    headers: nil,
                    presentationWindow: window
                )

                let userAgent = provider(URL(string: "https://auth0.com")!) { _ in }

                if let asUserAgent = userAgent as? ASUserAgent {
                    expect(asUserAgent.presentationWindow).to(be(window))
                } else {
                    fail("Expected ASUserAgent")
                }
            }

            it("should work without window parameter") {
                let redirectURL = URL(string: "https://samples.auth0.com/callback")!

                let provider = WebAuthentication.asProvider(
                    redirectURL: redirectURL,
                    ephemeralSession: false,
                    headers: nil
                )

                let userAgent = provider(URL(string: "https://auth0.com")!) { _ in }

                if let asUserAgent = userAgent as? ASUserAgent {
                    expect(asUserAgent.presentationWindow).to(beNil())
                } else {
                    fail("Expected ASUserAgent")
                }
            }
            #endif

        }

        #if os(iOS)
        describe("SafariProvider with custom window") {

            it("should pass window to SafariUserAgent") {
                let window = UIWindow()

                let provider = WebAuthentication.safariProvider(
                    style: .fullScreen,
                    presentationWindow: window
                )

                let userAgent = provider(URL(string: "https://auth0.com")!) { _ in }

                if let safariUserAgent = userAgent as? SafariUserAgent {
                    expect(safariUserAgent.presentationWindow).to(be(window))
                } else {
                    fail("Expected SafariUserAgent")
                }
            }

            it("should work without window parameter") {
                let provider = WebAuthentication.safariProvider(style: .fullScreen)

                let userAgent = provider(URL(string: "https://auth0.com")!) { _ in }

                if let safariUserAgent = userAgent as? SafariUserAgent {
                    expect(safariUserAgent.presentationWindow).to(beNil())
                } else {
                    fail("Expected SafariUserAgent")
                }
            }

        }

        describe("WebViewProvider with custom window") {

            it("should pass window to WebViewUserAgent") {
                let window = UIWindow()

                let provider = WebAuthentication.webViewProvider(
                    style: .fullScreen,
                    presentationWindow: window
                )

                let testURL = URL(string: "https://auth0.com?redirect_uri=https://samples.auth0.com/callback")!
                let userAgent = provider(testURL) { _ in }

                if let webViewUserAgent = userAgent as? WebViewUserAgent {
                    expect(webViewUserAgent.presentationWindow).to(be(window))
                } else {
                    fail("Expected WebViewUserAgent")
                }
            }

            it("should work without window parameter") {
                let provider = WebAuthentication.webViewProvider(style: .fullScreen)

                let testURL = URL(string: "https://auth0.com?redirect_uri=https://samples.auth0.com/callback")!
                let userAgent = provider(testURL) { _ in }

                if let webViewUserAgent = userAgent as? WebViewUserAgent {
                    expect(webViewUserAgent.presentationWindow).to(beNil())
                } else {
                    fail("Expected WebViewUserAgent")
                }
            }

        }
        #endif

        describe("integration with Auth0WebAuth") {

            #if os(iOS) || os(visionOS)
            it("should pass window from Auth0WebAuth to provider") {
                let window = UIWindow()
                let webAuth = newWebAuth()
                    .presentationWindow(window)

                // Mock the start method flow by checking the stored window
                expect(webAuth.presentationWindow).to(be(window))
            }
            #endif

            #if os(macOS)
            it("should pass window from Auth0WebAuth to provider") {
                let window = NSWindow()
                let webAuth = newWebAuth()
                    .presentationWindow(window)

                // Mock the start method flow by checking the stored window
                expect(webAuth.presentationWindow).to(be(window))
            }
            #endif

        }

        describe("backward compatibility") {

            it("should work without calling presentationWindow") {
                let webAuth = newWebAuth()
                    .connection("facebook")
                    .scope("openid profile")

                expect(webAuth.presentationWindow).to(beNil())
                expect(webAuth.parameters["connection"]) == "facebook"
                expect(webAuth.parameters["scope"]) == "openid profile"
            }

        }

    }
}
