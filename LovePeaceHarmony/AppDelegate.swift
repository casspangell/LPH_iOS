import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let loadingVC = LoadingViewController()
        window?.rootViewController = loadingVC
        window?.makeKeyAndVisible()

        AuthenticationManager.shared.autoLogin { success in
            DispatchQueue.main.async {
                let rootVC: UIViewController
                if success {
                    rootVC = MainTabBarController() // Replace with your main/home screen
                } else {
                    rootVC = LoginViewController() // Replace with your login screen
                }
                self.window?.rootViewController = rootVC
            }
        }
        return true
    }
} 