//
//  SignUpEmailController.swift
//  LovePeaceHarmony
//
//  Created by Aghil C M on 29/11/17.
//  Copyright © 2017 LovePeaceHarmony. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Firebase

class SignUpEmailController: BaseViewController, IndicatorInfoProvider, UITextFieldDelegate {
    
    // MARK: - Variables
    var loginControllerCallback: LoginControllerCallback?
    var splashDelegate: SplashDelegate?
    
    // MARK: - Colors
    private struct Colors {
        static let errorRed = UIColor.systemRed
    }
    
    // MARK: - IBOutlets
    @IBOutlet weak var textFieldEmail: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var textFieldConfirmPassword: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var backLabel: UILabel!
    @IBOutlet weak var createAccountLabel: UILabel!
    @IBOutlet weak var submitButton: LPHActionButton! {
        didSet {
            submitButton.setTitle(NSLocalizedString("Create Account", comment: ""))
        }
    }
    
    // MARK: - View
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        textFieldEmail.delegate = self
        textFieldPassword.delegate = self
        textFieldConfirmPassword.delegate = self
        
        setupTextFields()
        configureErrorLabel()
    }
    
    private func setupTextFields() {
        textFieldEmail.placeholder = NSLocalizedString("Email", comment: "")
        textFieldPassword.placeholder = NSLocalizedString("Password", comment: "")
        textFieldConfirmPassword.placeholder = NSLocalizedString("Confirm Password", comment: "")
        backLabel.text = NSLocalizedString("Back", comment: "")
        createAccountLabel.text = NSLocalizedString("Create an Account", comment: "")
        
        textFieldEmail.autocorrectionType = .no
        textFieldPassword.autocorrectionType = .no
        textFieldConfirmPassword.autocorrectionType = .no
        
        textFieldPassword.isSecureTextEntry = true
        textFieldConfirmPassword.isSecureTextEntry = true
        
        if #available(iOS 12.0, *) {
            textFieldEmail.textContentType = .username
            textFieldPassword.textContentType = .newPassword
            textFieldConfirmPassword.textContentType = .newPassword
        }
    }
    
    private func configureErrorLabel() {
        print("Configuring error label...")
        errorLabel.textColor = Colors.errorRed
        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.backgroundColor = .clear
        errorLabel.text = ""  // Initialize with empty string
        errorLabel.isHidden = true  // Start hidden
        errorLabel.alpha = 0  // Ensure alpha is 0 initially
        
        // Ensure proper sizing
        errorLabel.setContentHuggingPriority(.required, for: .vertical)
        errorLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // Remove any existing constraints
        errorLabel.removeFromSuperview()
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)
        
        // Add constraints to position between password field and submit button
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: textFieldConfirmPassword.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: textFieldConfirmPassword.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: textFieldConfirmPassword.trailingAnchor),
            submitButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16)
        ])
        
        print("Error label frame after constraints: \(errorLabel.frame)")
    }
    
    // MARK: - XLPagerTabStrip
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Title")
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == textFieldEmail {
            textFieldPassword.becomeFirstResponder()
        } else if textField == textFieldPassword {
            textFieldConfirmPassword.becomeFirstResponder()
        } else if textField == textFieldConfirmPassword {
            textField.resignFirstResponder()
            submitPressed(submitButton)
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Schedule hide with a slight delay when editing begins
        perform(#selector(hideError), with: nil, afterDelay: 0.1)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        let yValue = textField.layer.frame.maxY + 15
//        animateViewMoving(false, moveValue: yValue)
    }
    
    // MARK: - IBActions
    @IBAction func onTapBack(_ sender: UITapGestureRecognizer) {
        loginControllerCallback?.changeTab(index: 0)
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        print("Submit pressed")
        view.endEditing(true)
        
        // Don't hide error yet since we might need to show a new one
        submitButton.showLoading(loadingText: NSLocalizedString("Creating Account...", comment: ""))
        
        do {
            try validateForm()
        } catch let error as LPHException<LoginError> {
            print("Caught LPHException: \(error.errorMessage)")
            DispatchQueue.main.async {
                self.submitButton.showErrorState()
                self.showError(error.errorMessage)
            }
        } catch {
            print("Caught general error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.submitButton.showErrorState()
                self.showError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Error Handling
    private func showError(_ message: String) {
        print("Showing error: \(message)")
        
        // Cancel any pending hide animations
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideError), object: nil)
        
        // Update error label
        errorLabel.text = message
        errorLabel.isHidden = false
        
        // Force layout update
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        print("Error label after update - frame: \(errorLabel.frame), isHidden: \(errorLabel.isHidden)")
        
        // Ensure visibility with animation
        UIView.animate(withDuration: 0.3) {
            self.errorLabel.alpha = 1
        } completion: { finished in
            print("Show animation completed: \(finished)")
            print("Error label state - isHidden: \(self.errorLabel.isHidden), alpha: \(self.errorLabel.alpha)")
        }
    }
    
    @objc private func hideError() {
        print("Hiding error")
        guard !errorLabel.isHidden else { return }
        
        UIView.animate(withDuration: 0.3) {
            self.errorLabel.alpha = 0
        } completion: { finished in
            if finished {
                self.errorLabel.isHidden = true
                self.errorLabel.text = nil
                print("Error hidden - isHidden: \(self.errorLabel.isHidden), alpha: \(self.errorLabel.alpha)")
            }
        }
    }
    
    // MARK: - Actions
    private func validateForm() throws {
        guard let email = textFieldEmail.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            throw LPHException<LoginError>(controllerError: .emptyEmail)
        }
        
        if !LPHUtils.isValidEmail(email: email) {
            throw LPHException<LoginError>(controllerError: .invalidEmail)
        }
        
        guard let password = textFieldPassword.text,
              !password.isEmpty else {
            throw LPHException<LoginError>(controllerError: .emptyPassword)
        }
        
        guard password.count >= 6 else {
            throw LPHException<LoginError>(controllerError: .passwordLength)
        }
        
        guard let confirmPassword = textFieldConfirmPassword.text,
              !confirmPassword.isEmpty else {
            throw LPHException<LoginError>(controllerError: .emptyConfirmPassword)
        }
        
        guard password == confirmPassword else {
            throw LPHException<LoginError>(controllerError: .passwordDoNotMatch)
        }
        
        // Create account first, then handle FCM token
        Task {
            do {
                // Create Firebase user first
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                
                // Try to get FCM token, but don't fail if it doesn't work
                if let token = try? await Messaging.messaging().token() {
                    // Token retrieved successfully, update it
                    print("FCM token retrieved: \(token)")
                } else {
                    print("Failed to get FCM token, but continuing with account creation")
                }
                
                await MainActor.run {
                    // Process successful registration
                    processLoginResponse(email: email, password: password)
                    
                    // Show success state and navigate
                    submitButton.showSuccessState { [weak self] in
                        self?.navigateToHome()
                    }
                }
            } catch {
                await MainActor.run {
                    submitButton.showErrorState()
                    
                    let errorMessage: String
                    if let errorCode = AuthErrorCode.errorCode(from: error) {
                        switch errorCode {
                        case .emailAlreadyInUse:
                            errorMessage = NSLocalizedString("This email is already registered. Please try logging in.", comment: "")
                        case .invalidEmail:
                            errorMessage = NSLocalizedString("Invalid email format.", comment: "")
                        case .weakPassword:
                            errorMessage = NSLocalizedString("Password is too weak. Please use a stronger password.", comment: "")
                        case .networkError:
                            errorMessage = NSLocalizedString("Network error. Please check your connection.", comment: "")
                        default:
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    
                    showError(errorMessage)
                }
            }
        }
    }
    
    private func processLoginResponse(email: String, password: String) {
            let loginVo = LPHUtils.getLoginVo()
            loginVo.isLoggedIn = true
            loginVo.email = email
            loginVo.password = password
//            loginVo.fullName = profileVo.name
//            loginVo.profilePicUrl = profileVo.profilePic
            loginVo.loginType = .email
//            loginVo.inviteCode = profileVo.inviteCode
//            loginVo.token = response.getMetadata() as! String
            let user = LPHUtils.getCurrentUserID()
            LPHUtils.setLoginVo(loginVo: loginVo)
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
        
            LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isTutorialShown, value: true)
//            LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.isFirstRun, value: 1)
        
            self.fireUpdateTokenApi()
    }
    
    // MARK: - Apis
    private func fireSocialLoginRegisterApi(email: String,password: String, deviceId: String) {

    //Create New User
      Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in

          if let error = error {
            let authError = error as NSError
            self!.showAlert(title: "Error", message: authError.localizedDescription, vc: self!)
          }else{

            print("\(email) created")
            self?.processLoginResponse(email: email, password: password)
          }
        }
    }
    
    private func fireUpdateTokenApi() {
        // Since we already tried to get the token during account creation,
        // we can proceed directly to navigation
        self.hideLoadingIndicator()
        self.splashDelegate?.isFromLoginEnable()
        self.navigateToHome()
    }
    
    // MARK: - Navigation
    private func navigateToHome() {
        let homeTabController = LPHUtils.getStoryboard(type: .home).instantiateViewController(withIdentifier: ViewController.homeTab)
        
        let navVC = UINavigationController(rootViewController: homeTabController)
        navVC.setNavigationBarHidden(true, animated: false)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true, completion: nil)
    }
    
}
