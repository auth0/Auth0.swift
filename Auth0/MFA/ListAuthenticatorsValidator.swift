
struct ListAuthenticatorsValidator: RequestValidator {
    let factorsAllowed: [String]

    func validate() throws {
        if factorsAllowed.isEmpty {
            throw AuthenticationError.init(info: [:], statusCode: 0)
        }
    }
}
