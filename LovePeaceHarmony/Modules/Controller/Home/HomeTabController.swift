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
        
        if let accountItem = items[safe: 2] {
            accountItem.title = NSLocalizedString("Account", comment: "")
        }
    }
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
