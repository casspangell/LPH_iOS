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
        
        let items = homeTabController.items
        let chantItem = items![0]
        let aboutItem = items![1]
        let newsItem = items![2]
        let logoutItem = items![3]
        
        chantItem.title = NSLocalizedString("Chant", comment: "")
        aboutItem.title = NSLocalizedString("About", comment: "")
        newsItem.title = NSLocalizedString("News", comment: "")
        logoutItem.title = NSLocalizedString("Logout", comment: "")
        
    }
}
