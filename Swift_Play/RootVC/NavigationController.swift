//
//  NavigationController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/2/16.
//

import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupAppearance()
    }
    
    
    private func setupAppearance() -> Void {
        let appearance: UINavigationBarAppearance = UINavigationBarAppearance()
        
        appearance.backgroundColor = .yellow
        
        appearance.titleTextAttributes = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20),
            NSAttributedString.Key.foregroundColor : UIColor.white
        ]
        
        self.navigationBar.standardAppearance = appearance
        
        self.navigationBar.isTranslucent = true
        
        self.navigationBar.backgroundColor = .systemYellow

    }
}
