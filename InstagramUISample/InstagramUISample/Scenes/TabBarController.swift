//
//  TabBarController.swift
//  InstagramUISample
//
//  Created by 양준식 on 2022/04/04.
//

import UIKit


final class TabBarController: UITabBarController{
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let feedViewController = UIViewController()
        feedViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill"))
        
        let profileViewController = UIViewController()
        profileViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill"))
        
        
        viewControllers = [feedViewController, profileViewController]
        
    }
}
