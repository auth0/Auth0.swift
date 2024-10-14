// WebViewProviderSpec.swift

#if os(iOS)
import Quick
import Nimble
import WebKit
@testable import Auth0

private let Timeout: NimbleTimeInterval = .seconds(2)
private let LongerTimeout: NimbleTimeInterval = .seconds(5)

class WebViewProviderSpec: QuickSpec {
    
    override class func spec() {
        var webViewUserAgent: WebViewUserAgent!
        var callback: WebAuthProviderCallback!
        var mockViewController: UIViewController!
        var mockWebView: WKWebView!
        
        let authorizeURL = URL(string: "https://auth0.com/authorize?redirect_uri=https://auth0.com/callback")!
        let logoutURL = URL(string: "https://auth0.com/authorize?returnTo=https://auth0.com/callback")!
        let redirectURL = URL(string: "https://auth0.com/callback")!
        let customSchemeRedirectURL = URL(string: "customscheme://auth0.com/callback")!
        let code = "abc123"
        let customSchemeURLWithCode = URL(string: "\(customSchemeRedirectURL.absoluteString)?code=\(code)")!
        
        beforeEach {
            callback = { result in }
            mockViewController = UIViewController()
            mockWebView = WKWebView()
        }
        
        describe("WebAuthentication extension") {
            it("should create a WebView provider") {
                let provider = WebAuthentication.webViewProvider()
                expect(provider(authorizeURL, { _ in })).to(beAKindOf(WebViewUserAgent.self))
            }

            it("should use the fullscreen presentation style by default") {
                let provider = WebAuthentication.webViewProvider()
                let userAgent = provider(authorizeURL, { _ in }) as! WebViewUserAgent
                expect(userAgent.viewController.modalPresentationStyle) == .fullScreen
            }

            it("should set a custom presentation style") {
                let style = UIModalPresentationStyle.formSheet
                let provider = WebAuthentication.webViewProvider(style: style)
                let userAgent = provider(authorizeURL, { _ in }) as! WebViewUserAgent
                expect(userAgent.viewController.modalPresentationStyle) == .formSheet
            }
            
            it("should set the redirectURL correctly when using redirect_uri") {
                let provider = WebAuthentication.webViewProvider()
                let userAgent = provider(authorizeURL, { _ in }) as! WebViewUserAgent
                expect(userAgent.redirectURL).to(equal(redirectURL))
            }
            
            it("should set the redirectURL correctly when using returnTo") {
                let provider = WebAuthentication.webViewProvider()
                let userAgent = provider(logoutURL, { _ in }) as! WebViewUserAgent
                expect(userAgent.redirectURL).to(equal(redirectURL))
            }
        }
        
        describe("initialization") {
            it("should initialize with correct parameters") {
                let authorizeURL = URL(string: "https://auth0.com/authorize?redirect_uri=https://auth0.com/callback")!
                let redirectURL = URL(string: "https://auth0.com/callback")!
                webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                
                expect(webViewUserAgent.request.url).to(equal(authorizeURL))
                expect(webViewUserAgent.redirectURL).to(equal(redirectURL))
                expect(webViewUserAgent.callback).toNot(beNil())
                expect(webViewUserAgent.viewController).to(equal(mockViewController))
                expect(webViewUserAgent.webview).toNot(beNil())
                
                expect(webViewUserAgent.viewController.view).to(equal(webViewUserAgent.webview))
                expect(webViewUserAgent.webview.navigationDelegate).to(be(webViewUserAgent))
            }
            
            it("should initialize with custom scheme URLs and supply WKURLSchemeHandler") {
                let authorizeURL = URL(string: "customscheme://auth0.com/authorize?redirect_uri=customscheme://auth0.com/callback")!
                let redirectURL = URL(string: "customscheme://auth0.com/callback")!
                webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                
                expect(webViewUserAgent.request.url).to(equal(authorizeURL))
                expect(webViewUserAgent.redirectURL).to(equal(redirectURL))
                expect(webViewUserAgent.callback).toNot(beNil())
                expect(webViewUserAgent.viewController).to(equal(mockViewController))
                expect(webViewUserAgent.webview).toNot(beNil())
                
                let schemeHandler = webViewUserAgent.webview.configuration.urlSchemeHandler(forURLScheme: "customscheme")
                expect(schemeHandler).toNot(beNil())
                expect(webViewUserAgent.viewController.view).to(equal(webViewUserAgent.webview))
                expect(webViewUserAgent.webview.navigationDelegate).to(be(webViewUserAgent))
            }
        }
        
        describe("start") {
            it("should present view controller and load request") {
                let root = UIViewController()
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = root
                webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                webViewUserAgent.start()
                expect(webViewUserAgent.webview.url).to(equal(authorizeURL))
                expect(root.presentedViewController).to(equal(webViewUserAgent.viewController))
            }
            
            it("should present view controller and load request with custom scheme URLs") {
                let root = UIViewController()
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = root
                webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: customSchemeRedirectURL, viewController: mockViewController, callback: callback)
                webViewUserAgent.start()
                expect(webViewUserAgent.webview.url).to(equal(authorizeURL))
                expect(root.presentedViewController).to(equal(webViewUserAgent.viewController))
            }
        }
        
        describe("finish") {
            it("should dismiss view controller, remove webview, and call callback with success result") {
                let root = UIViewController()
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = root
                root.present(mockViewController, animated: false)
                
                waitUntil(timeout: LongerTimeout) { done in
                    callback = { result in
                        expect(root.presentedViewController).to(beNil())
                        expect(mockViewController.view.subviews.contains(webViewUserAgent.webview)).to(beFalse())
                        expect(result).to(beSuccessful())
                        done()
                    }
                    
                    webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                    webViewUserAgent.finish(with: .success(()))
                }
            }
            
            it("should dismiss view controller, remove webview, and call callback with failure result") {
                let root = UIViewController()
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = root
                root.present(mockViewController, animated: false)
                
                waitUntil(timeout: Timeout) { done in
                    callback = { result in
                        expect(root.presentedViewController).to(beNil())
                        expect(mockViewController.view.subviews.contains(webViewUserAgent.webview)).to(beFalse())
                        expect(result).to(haveWebAuthError(WebAuthError(code: .webViewFailure("An error occurred while starting to load data for the main frame of the WebView."))))
                        done()
                    }
                    
                    webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                    webViewUserAgent.finish(with: .failure(WebAuthError(code: .webViewFailure("An error occurred while starting to load data for the main frame of the WebView."))))
                }
            }
            
            it("should call the callback with an error when the view controller holding webview cannot be dismissed") {
                let error = WebAuthError(code: .unknown("Cannot dismiss WKWebView"))
                waitUntil(timeout: Timeout) { done in
                    callback = { result in
                        expect(mockViewController.view.subviews.contains(webViewUserAgent.webview)).to(beFalse())
                        expect(result).to(haveWebAuthError(error))
                        done()
                    }
                    
                    webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                    webViewUserAgent.finish(with: .failure(WebAuthError(code: .webViewFailure("An error occurred while starting to load data for the main frame of the WebView."))))
                }
            }
        }
        
        describe("WKURLSchemeHandler") {
            it("should handle custom scheme callbacks correctly") {
                webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: customSchemeRedirectURL, viewController: mockViewController, callback: callback)
                let mockCustomSchemeTask = MockURLSchemeTask(request: URLRequest(url: customSchemeURLWithCode))
                webViewUserAgent.webView(mockWebView, start: mockCustomSchemeTask)
                
                expect(mockCustomSchemeTask.didFailWithErrorCalled).to(beTrue())
                expect((mockCustomSchemeTask.error! as NSError).domain).to(equal(WebViewUserAgent.customSchemeRedirectionSuccessMessage))
                expect((mockCustomSchemeTask.error! as NSError).code).to(equal(200))
                expect((mockCustomSchemeTask.error! as NSError).localizedDescription).to(equal("WebViewProvider: WKURLSchemeHandler: Succesfully redirected back to the app"))
            }
            
            it("should handle custom scheme callbacks correctly when resource loading is stopped") {
                let root = UIViewController()
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = root
                root.present(mockViewController, animated: false)
                
                waitUntil(timeout: Timeout) { done in
                    callback = { result in
                        expect(result).to(haveWebAuthError(WebAuthError(code: .webViewFailure("The WebView's resource loading was stopped."))))
                        done()
                    }
                    webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: customSchemeRedirectURL, viewController: mockViewController, callback: callback)
                    let mockCustomSchemeTask = MockURLSchemeTask(request: URLRequest(url: customSchemeRedirectURL))
                    webViewUserAgent.webView(mockWebView, stop: mockCustomSchemeTask)
                    expect(mockCustomSchemeTask.didFailWithErrorCalled).to(beTrue())
                    expect((mockCustomSchemeTask.error! as NSError).domain).to(equal(WebViewUserAgent.customSchemeRedirectionFailureMessage))
                }
            }
        }

        describe("WKNavigationDelegate") {

            beforeEach {
                let root = UIViewController()
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = root
                root.present(mockViewController, animated: false)
            }

            it("should handle navigation actions correctly when a valid redirect URL is passed") {
                webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                
                let navigationAction = MockWKNavigationAction(url: redirectURL)
                var decisionHandlerCalled = false
                webViewUserAgent.webView(mockWebView, decidePolicyFor: navigationAction) { policy in
                    expect(policy).to(equal(.cancel))
                    decisionHandlerCalled = true
                }
                expect(decisionHandlerCalled).to(beTrue())
            }
            
            it("should handle navigation actions correctly when a invalid redirect URL is passed") {
                webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                
                let navigationAction = MockWKNavigationAction(url: URL(string:"https://okta.com/callback")!)
                var decisionHandlerCalled = false
                webViewUserAgent.webView(mockWebView, decidePolicyFor: navigationAction) { policy in
                    expect(policy).to(equal(.allow))
                    decisionHandlerCalled = true
                }
                expect(decisionHandlerCalled).to(beTrue())
            }
            
            it("should handle navigation failures correctly when an error during main frame navigation commiting") {
                waitUntil(timeout: Timeout) { done in
                    let error = NSError(domain: "WKWebViewNavigationFailure", code: 400)
                    callback = { result in
                        expect(result).to(haveWebAuthError(WebAuthError(code: .webViewFailure("An error occurred during a committed main frame navigation of the WebView."), cause: error)))
                        done()
                    }
                    webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                    webViewUserAgent.webView(mockWebView, didFail: nil, withError: error)
                }
            }
            
            it("should handle navigation failures correctly when starting to load data for main frame") {
                waitUntil(timeout: Timeout) { done in
                    let error = NSError(domain: "WKWebViewNavigationFailure", code: 400)
                    callback = { result in
                        expect(result).to(haveWebAuthError(WebAuthError(code: .webViewFailure("An error occurred while starting to load data for the main frame of the WebView."), cause: error)))
                        done()
                    }
                    webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                    webViewUserAgent.webView(mockWebView, didFailProvisionalNavigation: nil, withError: error)
                }
            }
            
            it("should handle webview failures correctly when content process terminated") {
                waitUntil(timeout: Timeout) { done in
                    callback = { result in
                        expect(result).to(haveWebAuthError(WebAuthError(code: .webViewFailure("The WebView's content process was terminated."))))
                        done()
                    }
                    webViewUserAgent = WebViewUserAgent(authorizeURL: authorizeURL, redirectURL: redirectURL, viewController: mockViewController, callback: callback)
                    webViewUserAgent.webViewWebContentProcessDidTerminate(mockWebView)
                }
            }
        }
    }
}

class MockURLSchemeTask: NSObject, WKURLSchemeTask {
    var didFailWithErrorCalled = false
    var error: Error?
    var request: URLRequest
    
    init(request: URLRequest) {
        self.request = request
    }
    
    func didReceive(_ response: URLResponse) {
        // Mock implementation
    }
    
    func didReceive(_ data: Data) {
        // Mock implementation
    }
    
    func didFinish() {
        // Mock implementation
    }
    
    func didFailWithError(_ error: Error) {
        didFailWithErrorCalled = true
        self.error = error
    }
}

class MockWKNavigationAction: WKNavigationAction {
    var mockRequest: URLRequest
    init(url: URL) {
        self.mockRequest = URLRequest(url: url)
    }
    override var request: URLRequest {
        return mockRequest
    }
}

#endif
