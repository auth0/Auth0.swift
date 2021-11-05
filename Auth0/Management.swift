import Foundation

public typealias ManagementObject = [String: Any]

/**
 *  Auth0 Management API
 */
struct Management: Trackable, Loggable {
    let token: String
    let url: URL
    var telemetry: Telemetry
    var logger: Logger?

    let session: URLSession

    init(token: String, url: URL, session: URLSession = .shared, telemetry: Telemetry = Telemetry()) {
        self.token = token
        self.url = url
        self.session = session
        self.telemetry = telemetry
    }

    func managementObject(response: Response<ManagementError>, callback: Request<ManagementObject, ManagementError>.Callback) {
        do {
            if let dictionary = try response.result() as? ManagementObject {
                callback(.success(dictionary))
            } else {
                callback(.failure(ManagementError(string: string(response.data))))
            }
        } catch let error {
            callback(.failure(error))
        }
    }

    func managementObjects(response: Response<ManagementError>, callback: Request<[ManagementObject], ManagementError>.Callback) {
        do {
            if let list = try response.result() as? [ManagementObject] {
                callback(.success(list))
            } else {
                callback(.failure(ManagementError(string: string(response.data))))
            }
        } catch let error {
            callback(.failure(error))
        }
    }

    var defaultHeaders: [String: String] {
        return [
            "Authorization": "Bearer \(token)"
        ]
    }
}
