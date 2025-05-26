//
//  HomeTabController.swift
//  LovePeaceHarmony
//
//  Created by Aghil C M on 07/11/17.
//  Updated by Cass Pangell on 9/5/21.
//  Copyright © 2017 LovePeaceHarmony. All rights reserved.
//

import UIKit

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
        
        if let newsItem = items[safe: 2] {
            newsItem.title = NSLocalizedString("News", comment: "")
        }
        
        // Only set logout if we have a fourth tab
        if let logoutItem = items[safe: 3] {
            logoutItem.title = NSLocalizedString("Logout", comment: "")
        }
    }
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
