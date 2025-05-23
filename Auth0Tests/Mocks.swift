import Foundation

@testable import Auth0

struct MockLogger: Logger {
    func trace(url: URL, source: String?) {}
    
    func trace(response: URLResponse, data: Data?) {}
    
    func trace(request: URLRequest, session: URLSession) {}
}

struct MockError: LocalizedError, CustomStringConvertible {
    private let message: String
    
    init(message: String = "foo") {
        self.message = message
    }
    
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
