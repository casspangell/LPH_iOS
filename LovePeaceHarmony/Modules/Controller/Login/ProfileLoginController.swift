//
//  ProfileLoginController.swift
//  LovePeaceHarmony
//
//  Created by Aghil C M on 05/12/17.
//  Updated by Cass Pangell on 3/23/20.
//  Copyright © 2017 LovePeaceHarmony. All rights reserved.
//

import UIKit
import Firebase

class ProfileLoginController: BaseViewController {
    
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var deleteAccountButton: UIButton!
    @IBOutlet weak var lphMessengerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func setupUI() {
        logoutButton.setTitle(NSLocalizedString("Logout", comment: ""), for: .normal)
        lphMessengerLabel.text = NSLocalizedString("Love Peace Harmony Messenger", comment: "")
        
        // Configure delete account button
        deleteAccountButton.setTitle(NSLocalizedString("Delete Account", comment: ""), for: .normal)
        deleteAccountButton.setTitleColor(.systemRed, for: .normal)
        deleteAccountButton.layer.borderColor = UIColor.systemRed.cgColor
        deleteAccountButton.layer.borderWidth = 1.0
        deleteAccountButton.layer.cornerRadius = 8.0
        deleteAccountButton.accessibilityLabel = NSLocalizedString("Delete account button", comment: "")
    }
    
    @IBAction func deleteAccountPressed(_ sender: Any) {
        showDeleteAccountWarning()
    }
    
    private func showDeleteAccountWarning() {
        let alert = UIAlertController(
            title: NSLocalizedString("Delete Account?", comment: ""),
            message: NSLocalizedString(
                "This action is permanent and cannot be undone. All your data will be deleted including:\n\n• Profile information\n• Settings\n• Progress data\n• Saved preferences\n\nAre you sure you want to continue?",
                comment: ""
            ),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel
        ))
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Continue", comment: ""),
            style: .destructive
        ) { [weak self] _ in
            self?.showFinalDeleteConfirmation()
        })
        
        present(alert, animated: true)
    }
    
    private func showFinalDeleteConfirmation() {
        let alert = UIAlertController(
            title: NSLocalizedString("Final Confirmation", comment: ""),
            message: NSLocalizedString("To confirm account deletion, please type DELETE", comment: ""),
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Type DELETE"
            textField.autocapitalizationType = .allCharacters
        }
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel
        ))
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Delete Account", comment: ""),
            style: .destructive
        ) { [weak self] _ in
            if let textField = alert.textFields?.first,
               textField.text?.uppercased() == "DELETE" {
                self?.performAccountDeletion()
            } else {
                self?.showError(message: NSLocalizedString("Please type DELETE to confirm", comment: ""))
            }
        })
        
        present(alert, animated: true)
    }
    
    private func performAccountDeletion() {
        guard let user = Auth.auth().currentUser else {
            showError(message: NSLocalizedString("No user signed in", comment: ""))
            return
        }
        
        showLoadingIndicator()
        
        // Check if re-authentication is needed
        let credential: AuthCredential? = nil // You might want to store the last sign-in method
        if let credential = credential {
            // Re-authenticate if needed
            user.reauthenticate(with: credential) { [weak self] _, error in
                if let error = error {
                    self?.handleDeletionError(error)
                    return
                }
                self?.deleteUserAccount(user)
            }
        } else {
            deleteUserAccount(user)
        }
    }
    
    private func deleteUserAccount(_ user: User) {
        user.delete { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleDeletionError(error)
                return
            }
            
            // Clear local data
            self.clearLocalData()
            
            // Stop audio and navigate to login
            AVAudioManager.sharedInstance.stop()
            self.hideLoadingIndicator()
            
            // Show success message and navigate
            self.showSuccessAndNavigate()
        }
    }
    
    private func handleDeletionError(_ error: Error) {
        hideLoadingIndicator()
        
        let nsError = error as NSError
        if let errorCode = AuthErrorCode(rawValue: nsError.code) {
            switch errorCode {
            case .requiresRecentLogin:
                showReauthenticationNeeded()
            default:
                showError(message: error.localizedDescription)
            }
        } else {
            showError(message: error.localizedDescription)
        }
    }
    
    private func showReauthenticationNeeded() {
        let alert = UIAlertController(
            title: NSLocalizedString("Re-authentication Required", comment: ""),
            message: NSLocalizedString("For security reasons, please sign out and sign in again before deleting your account.", comment: ""),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.logoutPressed(self as Any)
        })
        
        present(alert, animated: true)
    }
    
    private func clearLocalData() {
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Clear any other local storage or caches here
    }
    
    private func showSuccessAndNavigate() {
        let alert = UIAlertController(
            title: NSLocalizedString("Account Deleted", comment: ""),
            message: NSLocalizedString("Your account has been successfully deleted.", comment: ""),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.navigateToLogin()
        })
        
        present(alert, animated: true)
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("Error", comment: ""),
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default
        ))
        
        present(alert, animated: true)
    }
    
    @IBAction func logoutPressed(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        showLoadingIndicator()
        
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        
        AVAudioManager.sharedInstance.stop()
        self.hideLoadingIndicator()
        self.navigateToLogin()
    }
    
    private func navigateToLogin() {
        let homeTabController = LPHUtils.getStoryboard(type: .login).instantiateViewController(withIdentifier: ViewController.login)
        
        let navVC = UINavigationController(rootViewController: homeTabController)
        navVC.setNavigationBarHidden(true, animated: false)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true, completion: nil)
    }
}
