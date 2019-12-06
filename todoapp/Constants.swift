//
//  Constants.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/30/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    
    struct Segue {
        
        static let listToProfile    = "listToProfile"
        static let listToAddTask    = "listToAddTask"
        static let listToViewTask   = "listToViewTask"
        static let addToEditTask    = "addToEditTask"
        static let addTaskToFriend  = "addTaskToFriend"
        static let profileToFriend = "profileToFriend"
    }
    
    static let dateFormat = "dd MMM yyyy 'at' HH:mm"
    
    //
    static func showLogin() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let loginVC = storyBoard.instantiateInitialViewController()
        
        window.rootViewController = loginVC
        
        // A mask of options indicating how you want to perform the animations.
        let options: UIView.AnimationOptions = .transitionCrossDissolve
        
        // The duration of the transition animation, measured in seconds.
        let duration: TimeInterval = 0.3
        
        // Creates a transition animation.
        // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
        UIView.transition(with: window, duration: duration, options: options, animations: {}, completion:
            { completed in
                // maybe do something on completion here
        })
    }
    
    static func showHome() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "HomeNavVC") as! UINavigationController
        
        window.rootViewController = newViewController
        
        // A mask of options indicating how you want to perform the animations.
        let options: UIView.AnimationOptions = .transitionCrossDissolve
        
        // The duration of the transition animation, measured in seconds.
        let duration: TimeInterval = 0.3
        
        // Creates a transition animation.
        // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
        UIView.transition(with: window, duration: duration, options: options, animations: {}, completion:
            { completed in
                // maybe do something on completion here
        })
    }
}
