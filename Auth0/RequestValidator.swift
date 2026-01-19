/**
 Protocol for client-side validation of API request parameters before network calls.

 Conforming types implement custom validation logic to catch invalid request parameters
 early, preventing unnecessary network requests and providing clearer error messages.

 The `validate()` method is called by ``Request/runClientValidation()`` before constructing
 and sending the actual HTTP request. If validation fails, an error is thrown and the
 request is not sent.

 ## See Also

 - ``Request``
 - ``ListAuthenticatorsValidator``
 */
public protocol RequestValidator {

    /**
     Validates the request parameters.

     This method is called before the HTTP request is sent to the server. Implementations
     should check all relevant parameters and throw an error if any validation fails.

     - Throws: An error conforming to ``Auth0APIError`` describing the validation failure.
     */
    func validate() throws
}
