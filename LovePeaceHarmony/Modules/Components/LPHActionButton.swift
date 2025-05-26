import UIKit

/// A reusable button class that implements the app's standard action button style with loading and state animations
public final class LPHActionButton: UIButton {
    
    // MARK: - Types
    private struct Constants {
        static let cornerRadius: CGFloat = 5.0
        static let animationDuration: TimeInterval = 0.2
        static let successDelay: TimeInterval = 1.0
        static let errorDelay: TimeInterval = 1.5
    }
    
    private struct Colors {
        static let purpleDark = UIColor(red: 102/255, green: 45/255, blue: 145/255, alpha: 1.0)
        static let purpleLight = UIColor(red: 116/255, green: 110/255, blue: 175/255, alpha: 1.0)
        static let errorRed = UIColor.systemRed
    }
    
    // MARK: - Properties
    private var originalConfiguration: UIButton.Configuration?
    private var originalTitle: String?
    private var completionHandler: (() -> Void)?
    
    // MARK: - Initialization
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    // MARK: - Setup
    private func setupButton() {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = Colors.purpleDark
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        
        // Add padding between spinner and text
        config.imagePadding = 8
        
        // Save original configuration
        originalConfiguration = config
        configuration = config
        
        // Setup appearance
        layer.cornerRadius = Constants.cornerRadius
        layer.masksToBounds = true
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        clipsToBounds = false
        
        // Add touch down animation
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    // MARK: - Public Methods
    public func setTitle(_ title: String) {
        originalTitle = title
        var config = configuration
        config?.title = title
        configuration = config
    }
    
    public func showLoading(loadingText: String? = nil) {
        var config = configuration
        config?.showsActivityIndicator = true
        config?.title = loadingText
        configuration = config
        isEnabled = false
    }
    
    public func showSuccessState(completion: (() -> Void)? = nil) {
        completionHandler = completion
        
        var config = configuration
        config?.showsActivityIndicator = false
        config?.title = "✓"
        config?.baseBackgroundColor = Colors.purpleLight
        configuration = config
        
        // Add success animation
        UIView.animate(withDuration: Constants.animationDuration, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: Constants.animationDuration) {
                self.transform = .identity
            } completion: { _ in
                // Delay before calling completion
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.successDelay) {
                    self.completionHandler?()
                }
            }
        }
    }
    
    public func showErrorState() {
        var config = configuration
        config?.showsActivityIndicator = false
        config?.title = "!"
        config?.baseBackgroundColor = Colors.errorRed
        configuration = config
        
        // Add error animation
        UIView.animate(withDuration: Constants.animationDuration, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: Constants.animationDuration) {
                self.transform = .identity
            } completion: { _ in
                // Reset after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.errorDelay) {
                    self.resetToOriginalState()
                }
            }
        }
    }
    
    public func resetToOriginalState() {
        isEnabled = true
        configuration = originalConfiguration
        if let originalTitle = originalTitle {
            setTitle(originalTitle)
        }
    }
    
    // MARK: - Touch Animations
    @objc private func touchDown() {
        UIView.animate(withDuration: Constants.animationDuration) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.layer.shadowOffset = CGSize(width: 0, height: 1)
            self.layer.shadowRadius = 2
        }
    }
    
    @objc private func touchUp() {
        UIView.animate(withDuration: Constants.animationDuration) {
            self.transform = .identity
            self.layer.shadowOffset = CGSize(width: 0, height: 2)
            self.layer.shadowRadius = 4
        }
    }
} 