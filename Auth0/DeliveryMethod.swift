/// Delivery method for a phone-number passwordless OTP challenge.
public enum DeliveryMethod: String, Sendable {

    /// Deliver the OTP via SMS text message.
    case text

    /// Deliver the OTP via a voice call.
    case voice

}
