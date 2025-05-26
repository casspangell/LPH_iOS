//
//  LoginSocialNetworkController.swift
//  LovePeaceHarmony
//
//  Created by Aghil C M on 29/11/17.
//  Last Updated by Cass Pangell on 08/22/21.
//  Copyright © 2025 LovePeaceHarmony. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Firebase
import FirebaseAuth
import Alamofire

// Add the error code extension at the top level
extension AuthErrorCode {
    static func errorCode(from error: Error) -> AuthErrorCode? {
        return AuthErrorCode(rawValue: (error as NSError).code)
    }
}

class LoginSocialNetworkController: BaseViewController, IndicatorInfoProvider, UITextFieldDelegate {
    
    // MARK: - Variables
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    var loginControllerCallback: LoginControllerCallback?
    var splashDelegate: SplashDelegate?
    var loginEngine: SocialLoginEngine?
    private var errorLabel: UILabel!
    
    // MARK: - Colors
    private struct Colors {
        static let purpleDark = UIColor(red: 102/255, green: 45/255, blue: 145/255, alpha: 1.0)
        static let purpleLight = UIColor(red: 116/255, green: 110/255, blue: 175/255, alpha: 1.0)
    }
    
    // MARK: - IBOutlets
    @IBOutlet private weak var stackView: UIStackView! {
        didSet {
            stackView.setCustomSpacing(20, after: emailTextField)
            stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            stackView.isLayoutMarginsRelativeArrangement = true
        }
    }
    
    @IBOutlet private weak var emailTextField: UITextField! {
        didSet {
            configureTextField(emailTextField, 
                             placeholder: NSLocalizedString("Email", comment: ""),
                             contentType: .emailAddress)
        }
    }
    
    @IBOutlet private weak var passwordTextField: UITextField! {
        didSet {
            configureTextField(passwordTextField, 
                             placeholder: NSLocalizedString("Password", comment: ""),
                             contentType: .password,
                             isSecure: true)
        }
    }
    
    @IBOutlet private weak var loginButton: UIButton! {
        didSet {
            configureLoginButton()
        }
    }
    
    @IBOutlet private weak var noAccountButton: UIButton! {
        didSet {
            configureSignUpButton()
        }
    }
    
    @IBOutlet private weak var noAccountLabel: UILabel! {
        didSet {
            noAccountLabel.text = NSLocalizedString("Don't have an account? Sign Up", comment: "")
            noAccountLabel.adjustsFontForContentSizeCategory = true
        }
    }
    
    @IBOutlet private weak var forgotPasswordButton: UIButton! {
        didSet {
            configureForgotPasswordButton()
        }
    }
    
    // MARK: - Properties
    private let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    private let emailPredicate: NSPredicate = {
        NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAuthStateListener()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeAuthStateListener()
    }
    
    // MARK: - UI Configuration
    private func setupUI() {
        loginEngine = SocialLoginEngine(self)
        view.backgroundColor = .systemBackground
        
        setupErrorLabel()
        
        if #available(iOS 15.0, *) {
            // Use modern appearance customization
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
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
        
        // Insert error label into stack view after password field
        if let passwordIndex = stackView.arrangedSubviews.firstIndex(of: passwordTextField) {
            stackView.insertArrangedSubview(errorLabel, at: passwordIndex + 1)
            stackView.setCustomSpacing(8, after: passwordTextField)
            stackView.setCustomSpacing(16, after: errorLabel)
        }
    }
    
    private func configureNavigationBar() {
        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func configureTextField(_ textField: UITextField, placeholder: String, contentType: UITextContentType, isSecure: Bool = false) {
        textField.delegate = self
        textField.placeholder = placeholder
        textField.textContentType = contentType
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.clearButtonMode = .whileEditing
        textField.isSecureTextEntry = isSecure

    }
    
    private func configureLoginButton() {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("Login", comment: "")
        config.cornerStyle = .large
        config.buttonSize = .large
        config.baseBackgroundColor = Colors.purpleDark
        config.baseForegroundColor = .white
        
        loginButton.layer.shadowColor = UIColor.black.cgColor
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        loginButton.layer.shadowRadius = 4
        loginButton.layer.shadowOpacity = 0.1
        
        let touchDown = UILongPressGestureRecognizer(target: self, action: #selector(loginButtonTouchDown(_:)))
        touchDown.minimumPressDuration = 0
        loginButton.addGestureRecognizer(touchDown)
        
        loginButton.addTarget(self, action: #selector(loginWithEmailPressed(_:)), for: .touchUpInside)
        
        loginButton.configuration = config
    }
    
    private func configureSignUpButton() {
        var config = UIButton.Configuration.plain()
        config.buttonSize = .medium
        
        if #available(iOS 15.0, *) {
            config.baseBackgroundColor = .clear
            config.baseForegroundColor = .secondaryLabel
        }
        
        noAccountButton.configuration = config
    }
    
    private func configureForgotPasswordButton() {
        var config = UIButton.Configuration.plain()
        config.title = NSLocalizedString("Forgot Password?", comment: "")
        config.baseForegroundColor = Colors.purpleLight
        
        forgotPasswordButton.configuration = config
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
    }
    
    // MARK: - Authentication
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            if let user = user {
                print("👤 User successfully logged in - ID: \(user.uid)")
            }
        }
    }
    
    private func removeAuthStateListener() {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        clearErrorState()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: - Button Interaction
    @objc private func loginButtonTouchDown(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            animateButtonDown()
        case .ended:
            animateButtonUp()
            if let button = gesture.view as? UIButton,
               let touch = gesture.location(in: button) as CGPoint?,
               button.bounds.contains(touch) {
                loginWithEmailPressed(button)
            }
        case .cancelled:
            animateButtonUp()
        default:
            break
        }
    }
    
    private func animateButtonDown() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
            self.loginButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.loginButton.layer.shadowOffset = CGSize(width: 0, height: 1)
            self.loginButton.layer.shadowRadius = 2
            self.loginButton.configuration?.baseBackgroundColor = Colors.purpleLight
        })
    }
    
    private func animateButtonUp() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
            self.loginButton.transform = .identity
            self.loginButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            self.loginButton.layer.shadowRadius = 4
            self.loginButton.configuration?.baseBackgroundColor = Colors.purpleDark
        })
    }
    
    // MARK: - Actions
    @IBAction func loginWithEmailPressed(_ sender: Any) {
        let originalConfig = loginButton.configuration
        var updatedConfig = loginButton.configuration
        updatedConfig?.showsActivityIndicator = true
        updatedConfig?.title = NSLocalizedString("Logging in...", comment: "")
        updatedConfig?.baseBackgroundColor = Colors.purpleDark
        updatedConfig?.baseForegroundColor = .white
        loginButton.configuration = updatedConfig
        loginButton.isEnabled = false
        
        // Hide any previous error
        errorLabel.isHidden = true
        
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty,
              let password = passwordTextField.text,
              !password.isEmpty else {
            errorLabel.text = NSLocalizedString("Email and password are required", comment: "")
            errorLabel.isHidden = false
            loginButton.configuration = originalConfig
            loginButton.isEnabled = true
            return
        }
        
        showLoadingIndicator()
        
        Task {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                await MainActor.run {
                    hideLoadingIndicator()
                    updatedConfig?.showsActivityIndicator = false
                    updatedConfig?.title = "✓"
                    updatedConfig?.baseBackgroundColor = Colors.purpleLight
                    updatedConfig?.baseForegroundColor = .white
                    loginButton.configuration = updatedConfig
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.navigateToHome()
                    }
                }
            } catch {
                await MainActor.run {
                    hideLoadingIndicator()
                    updatedConfig?.showsActivityIndicator = false
                    updatedConfig?.title = "!"
                    updatedConfig?.baseBackgroundColor = Colors.purpleDark
                    updatedConfig?.baseForegroundColor = .white
                    loginButton.configuration = updatedConfig
                    
                    // Display error in the error label
                    let errorMessage: String
                    
                    if let errorCode = AuthErrorCode.errorCode(from: error) {
                        switch errorCode {
                        case .wrongPassword:
                            errorMessage = NSLocalizedString("Incorrect password. Please try again.", comment: "")
                        case .invalidEmail:
                            errorMessage = NSLocalizedString("Invalid email format.", comment: "")
                        case .userNotFound:
                            errorMessage = NSLocalizedString("No account found with this email.", comment: "")
                        case .networkError:
                            errorMessage = NSLocalizedString("Network error. Please check your connection.", comment: "")
                        case .tooManyRequests:
                            errorMessage = NSLocalizedString("Too many attempts. Please try again later.", comment: "")
                        default:
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    
                    self.errorLabel.text = errorMessage
                    self.errorLabel.isHidden = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.loginButton.configuration = originalConfig
                        self.loginButton.isEnabled = true
                    }
                }
            }
        }
    }
    
    @IBAction func signUpPressed(_ sender: Any) {
        if let loginController = parent as? LoginController {
            let targetIndex = loginController.viewControllerList.count - 1
            loginControllerCallback?.changeTab(index: targetIndex)
        } else {
            loginControllerCallback?.changeTab(index: 1)
        }
    }
    
    // MARK: - Navigation
    private func navigateToHome() {
        let homeTabController = LPHUtils.getStoryboard(type: .home).instantiateViewController(withIdentifier: ViewController.homeTab)
        
        let navVC = UINavigationController(rootViewController: homeTabController)
        navVC.modalPresentationStyle = .fullScreen
        navVC.setNavigationBarHidden(true, animated: false)
        present(navVC, animated: true)
    }
    
    // MARK: - XLPagerTabStrip
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Title")
    }
    
    // MARK: - Forgot Password
    @objc private func forgotPasswordTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("Reset Password", comment: ""),
            message: NSLocalizedString("Enter your email address and we'll send you a link to reset your password.", comment: ""),
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = NSLocalizedString("Email", comment: "")
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.clearButtonMode = .whileEditing
            if let email = self.emailTextField.text, !email.isEmpty {
                textField.text = email
            }
        }
        
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel
        )
        
        let resetAction = UIAlertAction(
            title: NSLocalizedString("Reset Password", comment: ""),
            style: .default
        ) { [weak self] _ in
            guard let self = self,
                  let email = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            else { return }
            
            self.handlePasswordReset(email: email)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(resetAction)
        present(alert, animated: true)
    }
    
    private func handlePasswordReset(email: String) {
        // Validate email format
        guard isValidEmail(email) else {
            showToast(message: NSLocalizedString("Please enter a valid email address", comment: ""))
            return
        }
        
        // Check network connectivity
        guard Reachability.isConnectedToNetwork() else {
            showToast(message: NSLocalizedString("No internet connection. Please check your network settings.", comment: ""))
            return
        }
        
        showLoadingIndicator()
        
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                await MainActor.run {
                    hideLoadingIndicator()
                    showSuccessAlert()
                }
            } catch {
                await MainActor.run {
                    hideLoadingIndicator()
                    handleResetError(error)
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        return emailPredicate.evaluate(with: email)
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("Check Your Email", comment: ""),
            message: NSLocalizedString("We've sent you an email with instructions to reset your password.", comment: ""),
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default
        )
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    private func handleResetError(_ error: Error) {
        var errorMessage = NSLocalizedString("Failed to send reset email. Please try again.", comment: "")
        
        if let errorCode = AuthErrorCode.errorCode(from: error) {
            switch errorCode {
            case .invalidEmail:
                errorMessage = NSLocalizedString("The email address is invalid.", comment: "")
            case .userNotFound:
                errorMessage = NSLocalizedString("No account exists with this email address.", comment: "")
            case .networkError:
                errorMessage = NSLocalizedString("Network error. Please check your connection and try again.", comment: "")
            case .tooManyRequests:
                errorMessage = NSLocalizedString("Too many attempts. Please try again later.", comment: "")
            default:
                errorMessage = error.localizedDescription
            }
        }
        
        showToast(message: errorMessage)
    }
    
    // MARK: - Reachability
    private struct Reachability {
        static func isConnectedToNetwork() -> Bool {
            guard let network = NetworkReachabilityManager() else { return false }
            return network.isReachable
        }
    }
    
    // Add helper method to clear error state
    private func clearErrorState() {
        errorLabel.isHidden = true
        errorLabel.text = nil
    }
}

