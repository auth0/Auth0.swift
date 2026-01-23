import Foundation
import Combine

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
    let requestValidator: [RequestValidator]
    let handle: (Result<ResponseValue, E>, Callback) -> Void
    let parameters: [String: Any]
    let headers: [String: String]
    let logger: Logger?
    let telemetry: Telemetry
    let dpop: DPoP?

    init(session: URLSession,
         url: URL,
         method: String,
         requestValidator: [RequestValidator] = [],
         handle: @escaping (Result<ResponseValue, E>, Callback) -> Void,
         parameters: [String: Any] = [:],
         headers: [String: String] = [:],
         logger: Logger?,
         telemetry: Telemetry,
         dpop: DPoP? = nil) {
        self.session = session
        self.url = url
        self.method = method
        self.handle = handle
        self.requestValidator = requestValidator
        self.parameters = parameters
        self.logger = logger
        self.telemetry = telemetry
        self.headers = headers
        self.dpop = dpop
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

    // MARK: - Request Handling

    /**
     Performs the request.

     - Parameter callback: Callback that receives the result of the request when it completes.
     */
    public func start(_ callback: @escaping Callback) {
        self.startDataTask(retryCount: 0, request: self.request, callback: callback)
    }

    private func startDataTask(retryCount: Int, request: URLRequest, callback: @escaping Callback) {
        var request = request

        do {
            try runClientValidation()
        } catch {
            handle(.failure(E(cause: error)), callback)
            return
        }
        do {
            if let dpop = dpop, try dpop.shouldGenerateProof(for: url, parameters: parameters) {
                let proof = try dpop.generateProof(for: request as URLRequest)
                request.setValue(proof, forHTTPHeaderField: "DPoP")
            }
        } catch {
            handle(.failure(E(cause: error)), callback)
            return
        }

        logger?.trace(request: request, session: self.session)

        let task = session.dataTask(with: request,
                                    completionHandler: { [logger, handle] data, response, error in
            if error == nil, let response = response {
                logger?.trace(response: response, data: data)
            }

            let response = Response<E>(data: data, response: response as? HTTPURLResponse, error: error)
            DPoP.storeNonce(from: response.response)

            do {
                handle(.success(try response.result()), callback)
            } catch let error as E {
                if DPoP.shouldRetry(for: error, retryCount: retryCount) {
                    startDataTask(retryCount: retryCount + 1, request: request, callback: callback)
                } else {
                    handle(.failure(error), callback)
                }
            } catch {
                handle(.failure(E(cause: error)), callback)
            }
        })
        task.resume()
    }

    func runClientValidation() throws {
        for validator in requestValidator {
            try validator.validate()
        }
    }

    // MARK: - Request Modifiers

    /**
     Modifies the parameters by creating a copy of the request and adding the provided parameters to the existing ones.

     - Parameter extraParameters: Additional parameters for the request.
     */
    public func parameters(_ extraParameters: [String: Any]) -> Self {
        var parameters = extraParameters.merging(self.parameters) {(current, _) in current}

        parameters["scope"] = includeRequiredScope(in: parameters["scope"] as? String)

        return Request(session: self.session,
                       url: self.url,
                       method: self.method,
                       handle: self.handle,
                       parameters: parameters,
                       headers: self.headers,
                       logger: self.logger,
                       telemetry: self.telemetry,
                       dpop: self.dpop)
    }

    /**
     Modifies the headers by creating a copy of the request and adding the provided headers to the existing ones.

     - Parameter extraHeaders: Additional headers for the request.
     */
    public func headers(_ extraHeaders: [String: String]) -> Self {
        let headers = extraHeaders.merging(self.headers) {(current, _) in current}

        return Request(session: self.session,
                       url: self.url,
                       method: self.method,
                       handle: self.handle,
                       parameters: self.parameters,
                       headers: headers,
                       logger: self.logger,
                       telemetry: self.telemetry,
                       dpop: self.dpop)
    }

    public func requestValidators(_ extraValidators: [RequestValidator]) -> Self {
        var requestValidator = extraValidators
        requestValidator.append(contentsOf: self.requestValidator)
        return Request(session: session,
                       url: url,
                       method: method,
                       requestValidator: requestValidator,
                       handle: handle,
                       parameters: parameters,
                       headers: headers,
                       logger: logger,
                       telemetry: telemetry,
                       dpop: dpop)
    }
}

// MARK: - Combine

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

#if canImport(_Concurrency)
public extension Request {

    /**
     Performs the request.

     - Throws: An error that conforms to ``Auth0APIError``; either an ``AuthenticationError`` or a ``ManagementError``.
     */
    func start() async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            self.start { result in
                continuation.resume(with: result)
            }
        }
    }

}
#endif
