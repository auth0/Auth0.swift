import Foundation
#if canImport(Combine)
import Combine
#endif

#if DEBUG
let parameterPropertyKey = "com.auth0.parameter"
#endif

/**
 Auth0 API request.

 ## Usage

 ```swift
 let request: Request<Credentials, AuthenticationError> = // ...
 
 request.start { result in
    print(result)
 }
 ```
 */
public struct Request<T, E: Auth0APIError>: Requestable {
    /**
     The callback closure type for the request.
     */
    public typealias Callback = (Result<T, E>) -> Void

    let session: URLSession
    let url: URL
    let method: String
    let handle: (Response<E>, Callback) -> Void
    let parameters: [String: Any]
    let headers: [String: String]
    let logger: Logger?
    let telemetry: Telemetry

    init(session: URLSession, url: URL, method: String, handle: @escaping (Response<E>, Callback) -> Void, parameters: [String: Any] = [:], headers: [String: String] = [:], logger: Logger?, telemetry: Telemetry) {
        self.session = session
        self.url = url
        self.method = method
        self.handle = handle
        self.parameters = parameters
        self.headers = headers
        self.logger = logger
        self.telemetry = telemetry
    }

    var request: URLRequest {
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = method
        if !parameters.isEmpty {
            if method.caseInsensitiveCompare("GET") == .orderedSame {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
                var queryItems = urlComponents?.queryItems ?? []
                let newQueryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
                queryItems.append(contentsOf: newQueryItems)
                urlComponents?.queryItems = queryItems
                request.url = urlComponents?.url ?? url
            } else if let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) {
                request.httpBody = httpBody
                #if DEBUG
                URLProtocol.setProperty(parameters, forKey: parameterPropertyKey, in: request)
                #endif
            }
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { name, value in request.setValue(value, forHTTPHeaderField: name) }
        telemetry.addTelemetryHeader(request: request)
        return request as URLRequest
    }

    /**
     Performs the request.

     - Parameter callback: Callback that receives the result of the request when it completes.
     */
    public func start(_ callback: @escaping Callback) {
        let handler = self.handle
        let request = self.request
        let logger = self.logger

        logger?.trace(request: request, session: self.session)

        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if error == nil, let response = response {
                logger?.trace(response: response, data: data)
            }
            handler(Response(data: data, response: response as? HTTPURLResponse, error: error), callback)
        })
        task.resume()
    }

    /**
     Modifies the parameters by creating a copy of the request and adding the provided parameters to the existing ones.

     - Parameter extraParameters: Additional parameters for the request.
     */
    public func parameters(_ extraParameters: [String: Any]) -> Self {
        var parameters = extraParameters.merging(self.parameters) {(current, _) in current}
        parameters["scope"] = includeRequiredScope(in: parameters["scope"] as? String)

        return Request(session: self.session, url: self.url, method: self.method, handle: self.handle, parameters: parameters, headers: self.headers, logger: self.logger, telemetry: self.telemetry)
    }

    /**
     Modifies the headers by creating a copy of the request and adding the provided headers to the existing ones.

     - Parameter extraHeaders: Additional headers for the request.
     */
    public func headers(_ extraHeaders: [String: String]) -> Self {
        let headers = extraHeaders.merging(self.headers) {(current, _) in current}

        return Request(session: self.session, url: self.url, method: self.method, handle: self.handle, parameters: self.parameters, headers: headers, logger: self.logger, telemetry: self.telemetry)
    }
}

// MARK: - Combine

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
public extension Request {

    /**
     Combine publisher for the request.

     - Returns: A type-erased publisher.
     */
    func start() -> AnyPublisher<T, E> {
        return Deferred { Future(self.start) }.eraseToAnyPublisher()
    }

}

// MARK: - Async/Await

#if compiler(>=5.5) && canImport(_Concurrency)
public extension Request {

    #if compiler(>=5.5.2)
    /**
     Performs the request.

     - Throws: An error that conforms to ``Auth0APIError``; either an ``AuthenticationError`` or a ``ManagementError``.
     */

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func start() async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            self.start(continuation.resume)
        }
    }
    #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func start() async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            self.start(continuation.resume)
        }
    }
    #endif

}
#endif
