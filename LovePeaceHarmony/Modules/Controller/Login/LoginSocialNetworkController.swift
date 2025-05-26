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

class LoginSocialNetworkController: BaseViewController, IndicatorInfoProvider, UITextFieldDelegate {
    
    // MARK: - Variables
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    var loginControllerCallback: LoginControllerCallback?
    var splashDelegate: SplashDelegate?
    var loginEngine: SocialLoginEngine?
    
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
        
        if #available(iOS 15.0, *) {
            // Use modern appearance customization
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
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
        // Handle text field focus if needed
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
        
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty,
              let password = passwordTextField.text,
              !password.isEmpty else {
            showToast(message: NSLocalizedString("Email/password can't be empty", comment: ""))
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
                    
                    showToast(message: error.localizedDescription)
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
}

