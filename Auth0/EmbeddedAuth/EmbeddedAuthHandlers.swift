import Foundation

// MARK: - Response decoders

func decodeDiscoveryResult(
    from result: Result<ResponseValue, EmbeddedAuthError>,
    callback: @Sendable (Result<DiscoveryResult, EmbeddedAuthError>) -> Void
) {
    switch result {
    case .failure(let error):
        callback(.failure(error))
    case .success(let response):
        guard let data = response.data else {
            callback(.failure(EmbeddedAuthError(from: response)))
            return
        }
        do {
            let decoded = try JSONDecoder().decode(DiscoveryResponse.self, from: data)
            callback(.success(DiscoveryResult(options: decoded.alternatives.compactMap(\.loginOption))))
        } catch {
            callback(.failure(EmbeddedAuthError(from: response)))
        }
    }
}
