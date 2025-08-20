//
//  MainViewController.swift
//  ABMate
//
//  Created by Bluetrum on 2022/2/15.
//

import UIKit

// MARK: - 根视图控制器
class MainViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTabBarItems()
    }
    
    private func setupTabBarItems() {
        let homeTitle = "tab_bar_title_home".localized
        let homeVC = HomeViewController()
        homeVC.title = homeTitle
        let homeNC = UINavigationController(rootViewController: homeVC)
        homeNC.tabBarItem = UITabBarItem(title: homeTitle, image: UIImage(named: "home"), selectedImage: nil)
        
        let functionTitle = "tab_bar_title_function".localized
        let functionVC = FunctionViewController()
        functionVC.title = functionTitle
        let functionNC = UINavigationController(rootViewController: functionVC)
        functionNC.tabBarItem = UITabBarItem(title: functionTitle, image: UIImage(named: "functions"), selectedImage: nil)
        
        viewControllers = [homeNC, functionNC]
    }
}
