//
//  LoginSocialNetworkController.swift
//  LovePeaceHarmony
//
//  Created by Aghil C M on 29/11/17.
//  Last Updated by Cass Pangell on 08/22/21.
//  Copyright © 2020 LovePeaceHarmony. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Firebase
import FirebaseAuth
import AuthenticationServices


class LoginSocialNetworkController: BaseViewController, IndicatorInfoProvider, UITextFieldDelegate {
    
    // MARK: - Variables
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    var loginControllerCallback: LoginControllerCallback?
    var splashDelegate: SplashDelegate?
    var loginEngine: SocialLoginEngine?
    
    // MARK: - IBOutets
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var noAccountButton: UIButton!
    @IBOutlet weak var noAccountLabel: UILabel!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureTextFields()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupAuthStateListener()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeAuthStateListener()
    }
    
    // MARK: - Setup
    private func setupUI() {
        loginEngine = SocialLoginEngine(self)
        
        //Set up UI labels for translation
        loginButton.configuration = .filled()
        loginButton.setTitle(NSLocalizedString("Login", comment: ""), for: .normal)
        
        emailTextField.placeholder = NSLocalizedString("Email", comment: "")
        passwordTextField.placeholder = NSLocalizedString("Password", comment: "")
        noAccountLabel.text = NSLocalizedString("Don't have an account? Sign Up", comment: "")
        
        if #available(iOS 15.0, *) {
            emailTextField.clearButtonMode = .whileEditing
            passwordTextField.clearButtonMode = .whileEditing
        }
    }
    
    private func configureTextFields() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        if #available(iOS 15.0, *) {
            emailTextField.textContentType = .emailAddress
            passwordTextField.textContentType = .password
        }
        
        passwordTextField.isSecureTextEntry = true
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            if let user = user {
                // User is signed in
                print("User is signed in with ID: \(user.uid)")
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
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Actions
    @IBAction func loginWithEmailPressed(_ sender: Any) {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty,
              let password = passwordTextField.text,
              !password.isEmpty else {
            showToast(message: NSLocalizedString("Email/password can't be empty", comment: ""))
            return
        }
        
        showLoadingIndicator()
        
        Task {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                hideLoadingIndicator()
                navigateToHome()
            } catch {
                hideLoadingIndicator()
                showToast(message: error.localizedDescription)
            }
        }
        
    }
    
    @IBAction func signUpPressed(_ sender: Any) {
        // Get the current number of tabs from the parent controller
        if let loginController = parent as? LoginController {
            let targetIndex = loginController.viewControllerList.count - 1
            loginControllerCallback?.changeTab(index: targetIndex)
        } else {
            // Fallback to the last tab
            loginControllerCallback?.changeTab(index: 1)
        }
    }
    
    // MARK: - XLPagerTabStrip
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Title")
    }
    
    // MARK: - Login Processing
    private func initiateLogin(type: LoginType) {
        Task {
            do {
                let token = try await Messaging.messaging().token()
                
                do {
                    try loginEngine?.initiateLogin(type) { [weak self] (lphResponse) in
                        guard let self = self else { return }
                        if lphResponse.isSuccess() {
                            let loginVo = lphResponse.getResult()
                            self.processLoginResponse(source: type, password: loginVo.password, token: token)
                        }
                    }
                } catch let exception as LPHException<LoginError> {
                    // Handle exception
                }
            } catch {
                print("Error fetching FCM token: \(error)")
            }
        }
    }
    
    private func processLoginResponse(source loginType: LoginType, password: String, token: String) {
        
        let isFirstRun = LPHUtils.getUserDefaultsInt(key: UserDefaults.Keys.isFirstRun)
        
        if isFirstRun == 0 {
                
            let loginVo = LPHUtils.getLoginVo()
            loginVo.isLoggedIn = true
            loginVo.loginType = loginType
            loginVo.password = password
            loginVo.token = token
            LPHUtils.setLoginVo(loginVo: loginVo)
            
            let user = LPHUtils.getCurrentUserID()
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
            LPHUtils.setUserDefaultsString(key: "\(user):\(UserDefaults.Keys.chantCurrentStreak)", value: "0")
            LPHUtils.setUserDefaultsString(key: "\(user):\(UserDefaults.Keys.chantLongestStreak)", value: "0")
            LPHUtils.setUserDefaultsString(key: "\(user):\(UserDefaults.Keys.chantTimestamp)", value: "0:00")
            
//            LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.isFirstRun, value: 1)
        }
    }
    
    // MARK: - Navigation
    private func navigateToHome() {
        let homeTabController = LPHUtils.getStoryboard(type: .home).instantiateViewController(withIdentifier: ViewController.homeTab)
        
        let navVC = UINavigationController(rootViewController: homeTabController)
        navVC.setNavigationBarHidden(true, animated: false)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true, completion: nil)
    }
    
    private func fireUpdateTokenApi() {
        var deviceToken = String()
        let deviceInfo = DEVICE_INFO
        showLoadingIndicator()

        Messaging.messaging().token { token, error in
          if let error = error {
            print("Error fetching FCM registration token: \(error)")
          } else if let token = token {
            print("FCM registration token: \(token)")
            deviceToken = token
          }
        }


        do {
            let lphService = try LPHServiceFactory<LoginError>.getLPHService()
            try lphService.updateDeviceToken(token: deviceToken, info: deviceInfo) { (parsedResponse) in
                self.hideLoadingIndicator()
                self.splashDelegate?.isFromLoginEnable()
                self.dismiss(animated: true, completion: nil)
            }
        } catch let error {

        }
    }
    
}

// MARK: - Apple Sign In Extension
@available(iOS 13.0, *)
extension LoginSocialNetworkController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func handleAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userId = appleIDCredential.user
            let userFirstName = appleIDCredential.fullName?.givenName
            let userLastName = appleIDCredential.fullName?.familyName
            let userEmail = appleIDCredential.email
            
            // Create Firebase credential
            if let identityToken = appleIDCredential.identityToken,
               let tokenString = String(data: identityToken, encoding: .utf8) {
                
                let credential = OAuthProvider.credential(
                    withProviderID: "apple.com",
                    idToken: tokenString,
                    rawNonce: nil
                )
                
                // Sign in with Firebase
                Task {
                    do {
                        let result = try await Auth.auth().signIn(with: credential)
                        navigateToHome()
                    } catch {
                        showToast(message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        showToast(message: error.localizedDescription)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
