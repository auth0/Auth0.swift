import Foundation

/**
 *  Auth0 Management API.
 */
struct Management: Trackable, Loggable {
    let token: String
    let url: URL
    let session: URLSession

    var telemetry: Telemetry
    var logger: Logger?

    var defaultHeaders: [String: String] {
        return [
            "Authorization": "Bearer \(token)"
        ]
    }

    init(token: String, url: URL, session: URLSession = .shared, telemetry: Telemetry = Telemetry()) {
        self.token = token
        self.url = url
        self.session = session
        self.telemetry = telemetry
    }

    func managementObject(result: Result<ResponseValue, ManagementError>, callback: Request<ManagementObject, ManagementError>.Callback) {
        do {
            let response = try result.get()
            if let dictionary = json(response.data) as? ManagementObject {
                callback(.success(dictionary))
            } else {
                callback(.failure(ManagementError(from: response)))
            }
        } catch {
            callback(.failure(error))
        }
    }

    func managementObjects(result: Result<ResponseValue, ManagementError>, callback: Request<[ManagementObject], ManagementError>.Callback) {
        do {
            let response = try result.get()
            if let list = json(response.data) as? [ManagementObject] {
                callback(.success(list))
            } else {
                callback(.failure(ManagementError(from: response)))
            }
        } catch {
            callback(.failure(error))
        }
    }
}
