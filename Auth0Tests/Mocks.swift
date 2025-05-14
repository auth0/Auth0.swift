import Foundation

@testable import Auth0

struct MockLogger: Logger {
    func trace(url: URL, source: String?) {}
    
    func trace(response: URLResponse, data: Data?) {}
    
    func trace(request: URLRequest, session: URLSession) {}
}

struct MockError: LocalizedError, CustomStringConvertible {
    private let message = "foo"
    
    var description: String {
        return self.message
    }
    
    var localizedDescription: String {
        return self.message
    }
    
    var errorDescription: String? {
        return self.message
    }
}
