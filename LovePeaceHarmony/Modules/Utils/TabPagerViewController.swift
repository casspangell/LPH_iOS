import UIKit
import MaterialShowcase

public protocol TabPageItem {
    var tabTitle: String { get }
    var viewController: UIViewController { get }
}

protocol TabPagerViewControllerDelegate: AnyObject {
    func tabPagerViewController(_ controller: TabPagerViewController, didSelectTabAt index: Int)
    func tabPagerViewController(_ controller: TabPagerViewController, didFinishAnimatingTo index: Int)
}

class TabPagerViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let pageViewController: UIPageViewController
    private let tabBarScrollView: UIScrollView
    private let tabStackView: UIStackView
    private let indicatorView: UIView
    
    private var tabButtons: [UIButton] = []
    private var viewControllers: [UIViewController] = []
    private var currentIndex: Int = 0
    
    weak var delegate: TabPagerViewControllerDelegate?
    
    // MARK: - Customization
    
    var tabBarHeight: CGFloat = 44.0 {
        didSet {
            tabBarHeightConstraint?.constant = tabBarHeight
            view.layoutIfNeeded()
        }
    }
    
    var selectedTabTextColor: UIColor = .black {
        didSet { updateTabAppearance() }
    }
    
    var unselectedTabTextColor: UIColor = .gray {
        didSet { updateTabAppearance() }
    }
    
    var indicatorColor: UIColor = .blue {
        didSet { indicatorView.backgroundColor = indicatorColor }
    }
    
    var tabFont: UIFont = .systemFont(ofSize: 16) {
        didSet { updateTabAppearance() }
    }
    
    // MARK: - Private Properties
    
    private var tabBarHeightConstraint: NSLayoutConstraint?
    private var indicatorLeadingConstraint: NSLayoutConstraint?
    private var indicatorWidthConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                navigationOrientation: .horizontal)
        tabBarScrollView = UIScrollView()
        tabStackView = UIStackView()
        indicatorView = UIView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                navigationOrientation: .horizontal)
        tabBarScrollView = UIScrollView()
        tabStackView = UIStackView()
        indicatorView = UIView()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPageViewController()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Tab Bar Setup
        view.addSubview(tabBarScrollView)
        tabBarScrollView.translatesAutoresizingMaskIntoConstraints = false
        tabBarScrollView.showsHorizontalScrollIndicator = false
        
        tabBarHeightConstraint = tabBarScrollView.heightAnchor.constraint(equalToConstant: tabBarHeight)
        
        NSLayoutConstraint.activate([
            tabBarScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tabBarScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarHeightConstraint!
        ])
        
        // Stack View Setup
        tabBarScrollView.addSubview(tabStackView)
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        tabStackView.axis = .horizontal
        tabStackView.spacing = 20
        tabStackView.distribution = .fillProportionally
        
        NSLayoutConstraint.activate([
            tabStackView.topAnchor.constraint(equalTo: tabBarScrollView.topAnchor),
            tabStackView.leadingAnchor.constraint(equalTo: tabBarScrollView.leadingAnchor, constant: 16),
            tabStackView.trailingAnchor.constraint(equalTo: tabBarScrollView.trailingAnchor, constant: -16),
            tabStackView.bottomAnchor.constraint(equalTo: tabBarScrollView.bottomAnchor)
        ])
        
        // Indicator Setup
        tabBarScrollView.addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.backgroundColor = indicatorColor
        
        indicatorLeadingConstraint = indicatorView.leadingAnchor.constraint(equalTo: tabStackView.leadingAnchor)
        indicatorWidthConstraint = indicatorView.widthAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            indicatorView.heightAnchor.constraint(equalToConstant: 2),
            indicatorView.bottomAnchor.constraint(equalTo: tabBarScrollView.bottomAnchor),
            indicatorLeadingConstraint!,
            indicatorWidthConstraint!
        ])
        
        // Page View Controller Setup - iOS 17 compatible
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: tabBarScrollView.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        pageViewController.didMove(toParentViewController: self)
    }
    
    private func setupPageViewController() {
        pageViewController.delegate = self
        pageViewController.dataSource = self
    }
    
    // MARK: - Public Methods
    
    func setViewControllers(_ items: [TabPageItem], initialIndex: Int = 0) {
        // Clear existing setup
        tabButtons.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()
        viewControllers.removeAll()
        tabStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Setup new controllers and tabs
        items.enumerated().forEach { index, item in
            let button = createTabButton(with: item.tabTitle, at: index)
            tabButtons.append(button)
            tabStackView.addArrangedSubview(button)
            viewControllers.append(item.viewController)
        }
        
        // Set initial view controller
        if !items.isEmpty {
            currentIndex = min(initialIndex, items.count - 1)
            pageViewController.setViewControllers([items[currentIndex].viewController],
                                                direction: .forward,
                                                animated: false,
                                                completion: nil)
            updateTabAppearance()
            updateIndicatorPosition(animated: false)
        }
    }
    
    func showTutorial(for index: Int, text: String) {
        guard index < tabButtons.count else { return }
        let button = tabButtons[index]
        
        let showcase = MaterialShowcase()
        showcase.setTargetView(view: button)
        showcase.primaryText = text
        showcase.primaryTextColor = .white
        showcase.backgroundPromptColor = .black
        showcase.targetHolderRadius = 30
        showcase.targetHolderColor = .clear
        showcase.show(completion: nil)
    }
    
    // MARK: - Private Methods
    
    private func createTabButton(with title: String, at index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = tabFont
        button.tag = index
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let targetIndex = sender.tag
        guard targetIndex != currentIndex else { return }
        
        let direction: UIPageViewController.NavigationDirection = targetIndex > currentIndex ? .forward : .reverse
        pageViewController.setViewControllers([viewControllers[targetIndex]],
                                            direction: direction,
                                            animated: true,
                                            completion: nil)
        
        currentIndex = targetIndex
        updateTabAppearance()
        updateIndicatorPosition()
        delegate?.tabPagerViewController(self, didSelectTabAt: targetIndex)
    }
    
    private func updateTabAppearance() {
        tabButtons.enumerated().forEach { index, button in
            button.setTitleColor(index == currentIndex ? selectedTabTextColor : unselectedTabTextColor,
                               for: .normal)
        }
    }
    
    private func updateIndicatorPosition(animated: Bool = true) {
        guard !tabButtons.isEmpty else { return }
        
        let targetButton = tabButtons[currentIndex]
        let newWidth = targetButton.intrinsicContentSize.width
        
        indicatorWidthConstraint?.constant = newWidth
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.indicatorLeadingConstraint?.constant = targetButton.frame.minX
                self.view.layoutIfNeeded()
            }
        } else {
            indicatorLeadingConstraint?.constant = targetButton.frame.minX
            view.layoutIfNeeded()
        }
        
        // Ensure the selected tab is visible
        let buttonFrame = targetButton.frame
        tabBarScrollView.scrollRectToVisible(buttonFrame, animated: animated)
    }
}

// MARK: - UIPageViewControllerDelegate & DataSource

extension TabPagerViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController), index > 0 else { return nil }
        return viewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController),
              index < viewControllers.count - 1 else { return nil }
        return viewControllers[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                          didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController],
                          transitionCompleted completed: Bool) {
        guard completed,
              let visibleViewController = pageViewController.viewControllers?.first,
              let index = viewControllers.firstIndex(of: visibleViewController) else { return }
        
        currentIndex = index
        updateTabAppearance()
        updateIndicatorPosition()
        delegate?.tabPagerViewController(self, didFinishAnimatingTo: index)
    }
}
