/**
 Validates that the `factorsAllowed` parameter contains at least one challenge type.

 This validator ensures that requests to list MFA authenticators include at least one
 factor type to filter by. If the array is empty, validation fails with an
 ``MfaListAuthenticatorsError`` before the network request is sent.

 ## See Also

 - ``RequestValidator``
 - ``MfaListAuthenticatorsError``
 */
struct ListAuthenticatorsValidator: RequestValidator {

    /// The array of challenge types to filter authenticators by.
    let factorsAllowed: [String]

    /**
     Validates that `factorsAllowed` is not empty.

     - Throws: ``MfaListAuthenticatorsError`` if the array is empty.
     */
    func validate() throws {
        if factorsAllowed.isEmpty {
        throw MfaListAuthenticatorsError(info: ["error": "invalid_request", "error_description": "challengeType is required and must contain at least one challenge type."])
        }
    }
}
