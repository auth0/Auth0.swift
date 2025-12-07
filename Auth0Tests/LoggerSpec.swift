import Foundation
import Quick
import Nimble

@testable import Auth0

final class MockLoggingService: UnifiedLogging {
    var loggedMessages: [(category: LogCategory, level: LogLevel, message: String)] = []
    
    func log(_ category: LogCategory, level: LogLevel, message: @autoclosure () -> String) {
        loggedMessages.append((category, level, message()))
    }
}

class LoggerSpec: QuickSpec {

    override class func spec() {

        describe("Auth0Log") {
            
            var mockService: MockLoggingService!
            
            beforeEach {
                mockService = MockLoggingService()
                Auth0Log.loggingService = mockService
            }
            
            afterEach {
                Auth0Log.loggingService = OSUnifiedLoggingService()
            }
            
            it("should have correct subsystem identifier") {
                expect(Auth0Log.subsystem) == "com.auth0.Auth0"
            }
            
            describe("log categories") {
                
                it("should have networkTracing category") {
                    expect(LogCategory.networkTracing.rawValue) == "NetworkTracing"
                }
                
                it("should have configuration category") {
                    expect(LogCategory.configuration.rawValue) == "Configuration"
                }
                
            }
            
            describe("debug method") {
                
                it("should log debug message with correct category") {
                    Auth0Log.debug(.networkTracing, "test debug")
                    expect(mockService.loggedMessages).to(haveCount(1))
                    expect(mockService.loggedMessages.first?.category) == .networkTracing
                    expect(mockService.loggedMessages.first?.level) == .debug
                    expect(mockService.loggedMessages.first?.message) == "test debug"
                }
                
            }
            
            describe("info method") {
                
                it("should log info message") {
                    Auth0Log.info(.configuration, "test info")
                    expect(mockService.loggedMessages.first?.level) == .info
                    expect(mockService.loggedMessages.first?.message) == "test info"
                }
                
            }
            
            describe("warning method") {
                
                it("should log warning message") {
                    Auth0Log.warning(.networkTracing, "test warning")
                    expect(mockService.loggedMessages.first?.level) == .warning
                    expect(mockService.loggedMessages.first?.message) == "test warning"
                }
                
            }
            
            describe("error method") {
                
                it("should log error message") {
                    Auth0Log.error(.configuration, "test error")
                    expect(mockService.loggedMessages.first?.level) == .error
                    expect(mockService.loggedMessages.first?.message) == "test error"
                }
                
            }
            
            describe("fault method") {
                
                it("should log fault message") {
                    Auth0Log.fault(.networkTracing, "test fault")
                    expect(mockService.loggedMessages.first?.level) == .fault
                    expect(mockService.loggedMessages.first?.message) == "test fault"
                }
                
            }
            
            describe("multiple logs") {
                
                it("should capture all logged messages") {
                    Auth0Log.debug(.networkTracing, "first")
                    Auth0Log.error(.configuration, "second")
                    Auth0Log.warning(.networkTracing, "third")
                    
                    expect(mockService.loggedMessages).to(haveCount(3))
                    expect(mockService.loggedMessages[0].message) == "first"
                    expect(mockService.loggedMessages[1].message) == "second"
                    expect(mockService.loggedMessages[2].message) == "third"
                }
                
            }
            
        }

        it("should build with default output") {
            let logger = DefaultLogger()
            expect(logger.output as? DefaultOutput).toNot(beNil())
        }

        var logger: Logger!
        var output: SpyOutput!

        beforeEach {
            output = SpyOutput()
            logger = DefaultLogger(output: output)
        }

        describe("request") {

            var request: URLRequest!

            beforeEach {
                request = URLRequest(url: URL(string: "https://auth0.com")!)
                request.httpMethod = "POST"
                request.allHTTPHeaderFields = ["Content-Type": "application/json"]
            }

            it("should log request basic info") {
                logger.trace(request: request, session: URLSession.shared)
                expect(output.messages.first) == "POST https://auth0.com HTTP/1.1"
            }

            it("should log request header") {
                logger.trace(request: request, session: URLSession.shared)
                expect(output.messages).to(contain("Content-Type: application/json"))
            }

            it("should log additional request header") {
                let sessionConfig = URLSession.shared.configuration
                sessionConfig.httpAdditionalHeaders = ["Accept": "application/json"]
                let urlSession = URLSession(configuration: sessionConfig)
                logger.trace(request: request, session: urlSession)
                expect(output.messages).to(contain("Accept: application/json"))
            }

            it("should log request body") {
                let json = "{key: \"\(UUID().uuidString)\"}"
                request.httpBody = json.data(using: .utf8)
                logger.trace(request: request, session: URLSession.shared)
                expect(output.messages).to(contain(json))
            }

            it("should log nothing for invalid request") {
                request.url = nil
                logger.trace(request: request, session: URLSession.shared)
                expect(output.messages).to(beEmpty())
            }

        }

        describe("response") {

            var response: HTTPURLResponse!

            beforeEach {
                response = HTTPURLResponse(url: URL(string: "https://auth0.com")!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])
            }

            it("should log response basic info") {
                logger.trace(response: response, data: nil)
                expect(output.messages.first) == "HTTP/1.1 200"
            }

            it("should log response header") {
                logger.trace(response: response, data: nil)
                expect(output.messages).to(contain("Content-Type: application/json"))
            }

            it("should log response body") {
                let json = "{key: \"\(UUID().uuidString)\"}"
                logger.trace(response: response, data: json.data(using: .utf8))
                expect(output.messages).to(contain(json))
            }

            it("should log nothing for non http response") {
                let response = URLResponse()
                logger.trace(response: response, data: nil)
                expect(output.messages).to(beEmpty())
            }

        }

        describe("url") {

            it("should log url") {
                logger.trace(url: URL(string: "https://samples.auth0.com/callback")!, source: nil)
                expect(output.messages.first) == "URL: https://samples.auth0.com/callback"
            }

            it("should log url with source") {
                logger.trace(url: URL(string: "https://samples.auth0.com/callback")!, source: "Safari")
                expect(output.messages.first) == "Safari: https://samples.auth0.com/callback"
            }

        }
    }
}

class SpyOutput: LoggerOutput {
    var messages: [String] = []

    func log(message: String) {
        messages.append(message)
    }

    func newLine() { }
}
