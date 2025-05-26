//
//  HomeTabController.swift
//  LovePeaceHarmony
//
//  Created by Aghil C M on 07/11/17.
//  Updated by Cass Pangell on 9/5/21.
//  Copyright © 2025 LovePeaceHarmony. All rights reserved.
//

import UIKit
import FirebaseAuth

class HomeTabController: UITabBarController {

    @IBOutlet weak var homeTabController: UITabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let items = homeTabController.items,
              items.count >= 3 else {
            print("Error: Not enough tab bar items configured")
            return
        }
        
        // Configure available tabs
        if let chantItem = items[safe: 0] {
            chantItem.title = NSLocalizedString("Chant", comment: "")
        }
        
        if let aboutItem = items[safe: 1] {
            aboutItem.title = NSLocalizedString("About", comment: "")
        }
        
        if let logoutItem = items[safe: 2] {
            logoutItem.title = NSLocalizedString("Logout", comment: "")
        }
        
        // Set up delegate to handle tab selection
        delegate = self
    }
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - UITabBarControllerDelegate
extension HomeTabController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Check if this is the logout tab (index 2)
        if let index = tabBarController.viewControllers?.firstIndex(of: viewController),
           index == 2 {
            // Show confirmation alert
            let alert = UIAlertController(
                title: NSLocalizedString("Logout", comment: ""),
                message: NSLocalizedString("Are you sure you want to log out?", comment: ""),
                preferredStyle: .alert
            )
            
            // Cancel action
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .cancel
            ))
            
            // Confirm logout action
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("Logout", comment: ""),
                style: .destructive
            ) { [weak self] _ in
                self?.performLogout()
            })
            
            present(alert, animated: true)
            return false
        }
        return true
    }
    
    private func performLogout() {
        do {
            try Auth.auth().signOut()
            // Clear local user data
            LPHUtils.clearLoginData()
            // Navigate to login screenType
            let loginController = LPHUtils.getStoryboard(type: .login).instantiateViewController(withIdentifier: ViewController.login)
            loginController.modalPresentationStyle = .fullScreen
            present(loginController, animated: true)
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            // Show error alert
            let alert = UIAlertController(
                title: NSLocalizedString("Error", comment: ""),
                message: NSLocalizedString("Failed to sign out. Please try again.", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            present(alert, animated: true)
        }
    }
}
