import Foundation

#if DEBUG
    let parameterPropertyKey = "com.auth0.parameter"
#endif

/**
 Auth0 API request

 ```
 let request: Request<Credentials, Authentication.Error> = //
 request.start { result in
    //handle result
 }
 ```
 */
public struct Request<T, E: Auth0Error>: Requestable {
    public typealias Callback = (Auth0Result<T>) -> Void

    let session: URLSession
    let url: URL
    let method: String
    let handle: (Response<E>, Callback) -> Void
    let payload: [String: Any]
    let headers: [String: String]
    let logger: Logger?
    let telemetry: Telemetry

    init(session: URLSession, url: URL, method: String, handle: @escaping (Response<E>, Callback) -> Void, payload: [String: Any] = [:], headers: [String: String] = [:], logger: Logger?, telemetry: Telemetry) {
        self.session = session
        self.url = url
        self.method = method
        self.handle = handle
        self.payload = payload
        self.headers = headers
        self.logger = logger
        self.telemetry = telemetry
    }

    var request: URLRequest {
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = method
        if !payload.isEmpty, let httpBody = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            request.httpBody = httpBody
            #if DEBUG
            URLProtocol.setProperty(payload, forKey: parameterPropertyKey, in: request)
            #endif
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { name, value in request.setValue(value, forHTTPHeaderField: name) }
        telemetry.addTelemetryHeader(request: request)
        return request as URLRequest
    }

    /**
     Starts the request to the server

     - parameter callback: called when the request finishes and yield it's result
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
            handler(Response(data: data, response: response, error: error), callback)
        })
        task.resume()
    }

    /**
     Modify the parameters by creating a copy of self and adding the provided parameters to `payload`.

     - parameter payload: Additional parameters for the request. The provided map will be added to `payload`.
     */
    public func parameters(_ payload: [String: Any]) -> Self {
        var parameter = self.payload
        payload.forEach { parameter[$0] = $1 }

        return Request(session: self.session, url: self.url, method: self.method, handle: self.handle, payload: parameter, headers: self.headers, logger: self.logger, telemetry: self.telemetry)
    }
}

/**
 *  A concatenated request, if the first one fails it will yield it's error, otherwise it will return the last request outcome
 */
public struct ConcatRequest<F, S, E: Auth0Error>: Requestable {
    let first: Request<F, E>
    let second: Request<S, E>

    public typealias ResultType = S

    /**
     Starts the request to the server

     - parameter callback: called when the request finishes and yield it's result
     */
    public func start(_ callback: @escaping (Auth0Result<ResultType>) -> Void) {
        let second = self.second
        first.start { result in
            switch result {
            case .failure(let cause):
                callback(.failure(cause))
            case .success:
                second.start(callback)
            }
        }
    }
}
