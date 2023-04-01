//
//  TabbarController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/2/16.
//

import UIKit

class TabbarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white

        self.setupAppearance()
        
        self.setupChildrenVC()
    }

    
    private func setupAppearance() -> Void {
        let appearance: UITabBarAppearance = UITabBarAppearance()
        
        appearance.backgroundColor = .yellow
        
//        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
//            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10),
//            NSAttributedString.Key.foregroundColor : UIColor.systemGray
//        ]
//        
//        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
//            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10),
//            NSAttributedString.Key.foregroundColor : UIColor.systemBlue
//        ]
//        
//        
//        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [
//            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10),
//            NSAttributedString.Key.foregroundColor : UIColor.systemGray
//        ]
//        
//        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [
//            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10),
//            NSAttributedString.Key.foregroundColor : UIColor.systemBlue
//        ]
        
        self.tabBar.standardAppearance = appearance
        
        self.tabBar.isTranslucent = false
        
        self.tabBar.backgroundColor = .systemYellow

    }

    
   private func setupChildrenVC() -> Void {
       /// 函数可以嵌套写：有时候某一块逻辑只需要在方法内复用或者做逻辑分割，可以在方法内定义方法，这样访问域会更清晰。
        func configVC(_ viewController: UIViewController, _ title: String, _ normalImageName:String, _ selectedImageName: String) -> Void {
            
           let tabBarItem: UITabBarItem = UITabBarItem(title: title, image: UIImage(named: normalImageName), selectedImage: UIImage(named: selectedImageName))
           
           let navVC: NavigationController = NavigationController(rootViewController: viewController)
           navVC.tabBarItem = tabBarItem
           navVC.tabBarItem = tabBarItem
           
           self.addChild(navVC)
        }

       
       
       let RxSwiftVC = RxSwiftViewController()
       configVC(RxSwiftVC, "RxSwift", "tab_settings", "tab_settings")
       
       let networkVC = NetworkViewController()
       configVC(networkVC, "Net", "tab_more", "tab_more")
       
       let CodingVC = CodableViewController()
       configVC(CodingVC, "CodingVC", "tab_settings", "tab_settings")
        
       let homeVC = HomeViewController()
       configVC(homeVC, "Home", "tab_home", "tab_home")
       
        let pageVC = PageViewController()
        configVC(pageVC, "Guess", "tab_group", "tab_group")

    }
    
    

}



