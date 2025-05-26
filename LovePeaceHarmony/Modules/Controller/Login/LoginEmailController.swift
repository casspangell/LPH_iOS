//
//  LoginEmailController.swift
//  LovePeaceHarmony
//
//  Created by Aghil C M on 29/11/17.
//  Copyright © 2017 LovePeaceHarmony. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Firebase

class LoginEmailController: BaseViewController, IndicatorInfoProvider, UITextFieldDelegate {
    
    // MARK: - Variables
    var loginControllerCallback: LoginControllerCallback?
    var splashDelegate: SplashDelegate?
    private var errorLabel: UILabel!
    private var serverResponseLabel: UILabel!
    
    // MARK: - IBOutlets
    @IBOutlet weak var textFieldEmail: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    
    // MARK: - View
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupErrorLabel()
        setupServerResponseLabel()
    }
    
    private func setupUI() {
        textFieldEmail.delegate = self
        textFieldPassword.delegate = self
        
        textFieldEmail.placeholder = NSLocalizedString("Email", comment: "")
        textFieldPassword.placeholder = NSLocalizedString("Password", comment: "")
        
        textFieldEmail.autocorrectionType = .no
        textFieldPassword.autocorrectionType = .no
        textFieldPassword.isSecureTextEntry = true
        
        if #available(iOS 12.0, *) {
            textFieldEmail.textContentType = .username
            textFieldPassword.textContentType = .password
        }
    }
    
    private func setupErrorLabel() {
        errorLabel = UILabel()
        errorLabel.textColor = .systemRed
        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .left
        errorLabel.isHidden = true
        errorLabel.adjustsFontForContentSizeCategory = true
        
        // Add error label to view hierarchy
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)
        
        // Constrain error label below password field
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: textFieldPassword.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: textFieldPassword.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: textFieldPassword.trailingAnchor)
        ])
    }
    
    private func setupServerResponseLabel() {
        serverResponseLabel = UILabel()
        serverResponseLabel.textColor = .systemGray
        serverResponseLabel.font = .preferredFont(forTextStyle: .footnote)
        serverResponseLabel.numberOfLines = 0
        serverResponseLabel.textAlignment = .left
        serverResponseLabel.isHidden = true
        serverResponseLabel.adjustsFontForContentSizeCategory = true
        
        // Add server response label to view hierarchy
        serverResponseLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(serverResponseLabel)
        
        // Constrain server response label below error label
        NSLayoutConstraint.activate([
            serverResponseLabel.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 4),
            serverResponseLabel.leadingAnchor.constraint(equalTo: errorLabel.leadingAnchor),
            serverResponseLabel.trailingAnchor.constraint(equalTo: errorLabel.trailingAnchor)
        ])
    }
    
    private func showServerResponse(_ message: String) {
        serverResponseLabel.text = message
        
        // Animate the server response label appearance
        serverResponseLabel.alpha = 0
        serverResponseLabel.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.serverResponseLabel.alpha = 1
        }
    }
    
    private func hideServerResponse() {
        UIView.animate(withDuration: 0.3) {
            self.serverResponseLabel.alpha = 0
        } completion: { _ in
            self.serverResponseLabel.isHidden = true
            self.serverResponseLabel.text = nil
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == textFieldEmail {
            textFieldPassword.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            handleLogin()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Hide error and server response when user starts typing
        hideError()
        hideServerResponse()
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        
        // Animate the error label appearance
        errorLabel.alpha = 0
        errorLabel.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.errorLabel.alpha = 1
        }
    }
    
    private func hideError() {
        UIView.animate(withDuration: 0.3) {
            self.errorLabel.alpha = 0
        } completion: { _ in
            self.errorLabel.isHidden = true
            self.errorLabel.text = nil
        }
    }
    
    // MARK: - Login
    @IBAction func loginButtonPressed(_ sender: Any) {
        handleLogin()
    }
    
    private func handleLogin() {
        view.endEditing(true)
        hideError()
        hideServerResponse()
        
        guard let email = textFieldEmail.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showError(NSLocalizedString("Please enter your email", comment: ""))
            return
        }
        
        guard let password = textFieldPassword.text,
              !password.isEmpty else {
            showError(NSLocalizedString("Please enter your password", comment: ""))
            return
        }
        
        // Check email format
        if !isValidEmail(email) {
            showError(NSLocalizedString("Please enter a valid email address", comment: ""))
            return
        }
        
        showLoadingIndicator()
        
        // Sign in with Firebase
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            self.hideLoadingIndicator()
            
            if let error = error {
                self.handleLoginError(error)
                return
            }
            
            // Login successful
            self.handleSuccessfulLogin(email: email, password: password)
        }
    }
    
    private func handleSuccessfulLogin(email: String, password: String) {
        // Update login button to show success state
        if let loginButton = view.viewWithTag(100) as? UIButton {
            var config = loginButton.configuration ?? UIButton.Configuration.filled()
            config.showsActivityIndicator = false
            config.title = "✓"
            config.baseBackgroundColor = UIColor(red: 102/255, green: 45/255, blue: 145/255, alpha: 1.0)
            loginButton.configuration = config
            
            // Add success animation
            UIView.animate(withDuration: 0.2, animations: {
                loginButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    loginButton.transform = .identity
                }
            }
        }

        // Update user data
        let loginVo = LPHUtils.getLoginVo()
        loginVo.isLoggedIn = true
        loginVo.email = email
        loginVo.password = password
        loginVo.loginType = .email
        
        // Save login state
        LPHUtils.setLoginVo(loginVo: loginVo)
        
        // Set default preferences for new login
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.mandarinSoulEnglish, value: true)
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isInstrumentalOn, value: true)
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isHindi_SL_EnglishOn, value: false)
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isSpanishOn, value: false)
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isMandarinEnglishGermanOn, value: false)
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isFrenchOn, value: false)
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isfrenchAntilleanCreoleOn, value: false)
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isKawehiHawOn, value: false)
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isShaEngOn, value: false)
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isShaLulaEngKaHawOn, value: false)
        
        // Initialize user stats
        if let user = Auth.auth().currentUser?.uid {
            LPHUtils.setUserDefaultsString(key: "\(user):\(UserDefaults.Keys.chantCurrentStreak)", value: "0")
            LPHUtils.setUserDefaultsString(key: "\(user):\(UserDefaults.Keys.chantLongestStreak)", value: "0")
            LPHUtils.setUserDefaultsString(key: "\(user):\(UserDefaults.Keys.chantTimestamp)", value: "0:00")
        }
        
        // Set tutorial state
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isTutorialShown, value: true)
        
        // Get FCM token and navigate, with error handling
        Messaging.messaging().token { [weak self] token, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Warning: FCM token fetch failed: \(error.localizedDescription)")
                // Log the detailed error for debugging
                print("Detailed FCM error: \(error)")
                
                // Show a non-blocking warning in the server response label
                DispatchQueue.main.async {
                    self.showServerResponse(NSLocalizedString("Notification services temporarily unavailable", comment: ""))
                }
                
                // Continue with navigation despite FCM token error
                DispatchQueue.main.async {
                    self.completeLoginAndNavigate()
                }
                return
            }
            
            if let token = token {
                print("FCM registration token successfully obtained: \(token)")
            }
            
            // Proceed with navigation
            DispatchQueue.main.async {
                self.completeLoginAndNavigate()
            }
        }
    }
    
    private func completeLoginAndNavigate() {
        // Notify delegate
        self.splashDelegate?.isFromLoginEnable()
        
        // Add transition animation
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0.0
        }) { _ in
            self.navigateToHome()
        }
    }
    
    private func handleLoginError(_ error: Error) {
        var errorMessage = NSLocalizedString("Failed to sign in. Please try again.", comment: "")
        var serverMessage: String?
        
        // Handle Firebase Auth errors
        if let errorCode = AuthErrorCode.errorCode(from: error) {
            switch errorCode {
            case .wrongPassword:
                errorMessage = NSLocalizedString("Incorrect password. Please try again.", comment: "")
            case .invalidEmail:
                errorMessage = NSLocalizedString("Invalid email format.", comment: "")
            case .userNotFound:
                errorMessage = NSLocalizedString("No account found with this email.", comment: "")
            case .userDisabled:
                errorMessage = NSLocalizedString("This account has been disabled.", comment: "")
            case .tooManyRequests:
                errorMessage = NSLocalizedString("Too many attempts. Please try again later.", comment: "")
                serverMessage = NSLocalizedString("Server is temporarily blocking requests. Please try again in a few minutes.", comment: "")
            case .networkError:
                errorMessage = NSLocalizedString("Network error. Please check your connection.", comment: "")
                serverMessage = NSLocalizedString("Unable to reach authentication server. Please verify your internet connection.", comment: "")
            default:
                if (error as NSError).domain == "FIRAuthErrorDomain" {
                    // This is a server-related Firebase error
                    errorMessage = NSLocalizedString("Authentication error", comment: "")
                    serverMessage = error.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            // For non-Firebase errors, check if it's server-related
            let nsError = error as NSError
            if nsError.domain.contains("Server") || nsError.domain.contains("Network") {
                errorMessage = NSLocalizedString("Server connection error", comment: "")
                serverMessage = error.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        showError(errorMessage)
        
        if let serverMessage = serverMessage {
            showServerResponse(serverMessage)
        }
        
        // Log error for debugging
        print("Login error: \(error.localizedDescription)")
    }
    
    private func isNetworkReachable() -> Bool {
        return true // Simplified check, Firebase will handle network errors
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Navigation
    private func navigateToHome() {
        let homeTabController = LPHUtils.getStoryboard(type: .home).instantiateViewController(withIdentifier: ViewController.homeTab)
        homeTabController.modalPresentationStyle = .fullScreen
        homeTabController.modalTransitionStyle = .crossDissolve
        
        // Present with completion to ensure smooth transition
        present(homeTabController, animated: true) { [weak self] in
            // Reset the login view state for next time
            self?.view.alpha = 1.0
            self?.textFieldEmail.text = nil
            self?.textFieldPassword.text = nil
            
            if let loginButton = self?.view.viewWithTag(100) as? UIButton {
                var config = loginButton.configuration ?? UIButton.Configuration.filled()
                config.showsActivityIndicator = false
                config.title = NSLocalizedString("Login", comment: "")
                loginButton.configuration = config
            }
        }
    }
    
    // MARK: - XLPagerTabStrip
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Title")
    }
}
