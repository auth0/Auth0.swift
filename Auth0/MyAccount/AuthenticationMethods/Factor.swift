/// List of factors enabled for the Auth0 tenant and available for enrollment by this user.
public struct Factors: Decodable {
    public let factors: [Factor]
}

public struct Factor: Decodable {
    /// Authentication method type (factor)
    public let type: String?

    /// Primary and/or secondary factor
    public let usage: [String]
}
