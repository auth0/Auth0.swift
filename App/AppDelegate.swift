import UIKit
import Auth0

typealias A0ApplicationLaunchOptionsKey = UIApplication.LaunchOptionsKey

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [A0ApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [A0URLOptionsKey : Any]) -> Bool {
        return Auth0.resumeAuth(url)
    }
}

