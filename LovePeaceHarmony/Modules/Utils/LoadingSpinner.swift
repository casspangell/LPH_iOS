import UIKit

/// A modern loading spinner overlay that can be displayed on any view or view controller
final class LoadingSpinner {
    
    // MARK: - Singleton
    static let shared = LoadingSpinner()
    private init() {}
    
    // MARK: - Properties
    private var containerView: UIView?
    private var timeoutTimer: Timer?
    private let timeoutInterval: TimeInterval = 30.0 // Default timeout of 30 seconds
    
    // MARK: - UI Components
    private lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var spinnerView: UIActivityIndicatorView = {
        let spinner: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(activityIndicatorStyle: .large)
        } else {
            spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        }
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = .systemIndigo
        return spinner
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        return stack
    }()
    
    // MARK: - Public Methods
    
    /// Shows the loading spinner on a view
    /// - Parameters:
    ///   - view: The view to show the spinner on
    ///   - message: Optional message to display below the spinner
    ///   - timeout: Optional timeout interval (defaults to 30 seconds)
    func show(on view: UIView, message: String? = nil, timeout: TimeInterval? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.showOnMain(on: view, message: message, timeout: timeout)
        }
    }
    
    /// Shows the loading spinner on a view controller
    /// - Parameters:
    ///   - viewController: The view controller to show the spinner on
    ///   - message: Optional message to display below the spinner
    ///   - timeout: Optional timeout interval (defaults to 30 seconds)
    func show(on viewController: UIViewController, message: String? = nil, timeout: TimeInterval? = nil) {
        show(on: viewController.view, message: message, timeout: timeout)
    }
    
    /// Hides the loading spinner
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.hideOnMain()
        }
    }
    
    // MARK: - Private Methods
    
    private func showOnMain(on view: UIView, message: String?, timeout: TimeInterval?) {
        // Cancel any existing timeout timer
        timeoutTimer?.invalidate()
        
        // Remove any existing spinner
        hideOnMain()
        
        containerView = view
        
        // Setup views
        view.addSubview(overlayView)
        overlayView.addSubview(blurView)
        overlayView.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(spinnerView)
        if let message = message {
            messageLabel.text = message
            contentStackView.addArrangedSubview(messageLabel)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            blurView.topAnchor.constraint(equalTo: overlayView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor),
            
            contentStackView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: overlayView.leadingAnchor, constant: 32),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: overlayView.trailingAnchor, constant: -32)
        ])
        
        // Animate appearance
        overlayView.alpha = 0
        spinnerView.startAnimating()
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.overlayView.alpha = 1
        }
        
        // Setup timeout if specified
        let timeoutDuration = timeout ?? timeoutInterval
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutDuration, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }
    
    private func hideOnMain() {
        guard containerView != nil else { return }
        
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.overlayView.alpha = 0
        }, completion: { [weak self] _ in
            self?.spinnerView.stopAnimating()
            self?.overlayView.removeFromSuperview()
            self?.messageLabel.text = nil
            self?.containerView = nil
        })
    }
}

// MARK: - Convenience Extensions
extension UIViewController {
    /// Shows a loading spinner on the view controller
    /// - Parameters:
    ///   - message: Optional message to display below the spinner
    ///   - timeout: Optional timeout interval (defaults to 30 seconds)
    func showLoadingSpinner(message: String? = nil, timeout: TimeInterval? = nil) {
        LoadingSpinner.shared.show(on: self, message: message, timeout: timeout)
    }
    
    /// Hides the loading spinner
    func hideLoadingSpinner() {
        LoadingSpinner.shared.hide()
    }
}

extension UIView {
    /// Shows a loading spinner on the view
    /// - Parameters:
    ///   - message: Optional message to display below the spinner
    ///   - timeout: Optional timeout interval (defaults to 30 seconds)
    func showLoadingSpinner(message: String? = nil, timeout: TimeInterval? = nil) {
        LoadingSpinner.shared.show(on: self, message: message, timeout: timeout)
    }
    
    /// Hides the loading spinner
    func hideLoadingSpinner() {
        LoadingSpinner.shared.hide()
    }
} 
