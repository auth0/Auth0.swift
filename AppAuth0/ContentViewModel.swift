import Combine
import Foundation
import Auth0

final class ContentViewModel: ObservableObject {
    let credentialsManager: CredentialsManager

    init(credentialsManager: CredentialsManager) {
        self.credentialsManager = credentialsManager
    }
}
