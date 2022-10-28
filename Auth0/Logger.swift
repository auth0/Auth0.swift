import Foundation

/// Logger for debugging purposes.
public protocol Logger {

    /// Log an HTTP request.
    func trace(request: URLRequest, session: URLSession)

    /// Log an HTTP response.
    func trace(response: URLResponse, data: Data?)

    /// Log a URL.
    func trace(url: URL, source: String?)

}

protocol LoggerOutput {
    func log(message: String)
    func newLine()
}

struct DefaultOutput: LoggerOutput {
    func log(message: String) { print(message) }
    func newLine() { print() }
}

struct DefaultLogger: Logger {

    let output: LoggerOutput

    init(output: LoggerOutput = DefaultOutput()) {
        self.output = output
    }

    func trace(request: URLRequest, session: URLSession) {
        guard let method = request.httpMethod, let url = request.url?.absoluteString else { return }
        output.log(message: "\(method) \(url) HTTP/1.1")
        session.configuration.httpAdditionalHeaders?.forEach { key, value in output.log(message: "\(key): \(value)") }
        request.allHTTPHeaderFields?.forEach { key, value in output.log(message: "\(key): \(value)") }
        if let data = request.httpBody, let string = String(data: data, encoding: .utf8) {
            output.newLine()
            output.log(message: string)
        }
        output.newLine()
    }

    func trace(response: URLResponse, data: Data?) {
        if let http = response as? HTTPURLResponse {
            output.log(message: "HTTP/1.1 \(http.statusCode)")
            http.allHeaderFields.forEach { key, value in output.log(message: "\(key): \(value)") }
            if let data = data, let string = String(data: data, encoding: .utf8) {
                output.newLine()
                output.log(message: string)
            }
            output.newLine()
        }
    }

    func trace(url: URL, source: String?) {
        output.log(message: "\(source ?? "URL"): \(url.absoluteString)")
    }

}
