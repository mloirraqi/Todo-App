//
//  AddFriendVC.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/30/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import UIKit

class AddFriendVC: UIViewController {
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var userTextField: UITextField!
    
    
    //View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    @IBAction func addPressed(_ sender: Any) {
        if let friendUsername = userTextField.text {
            FirebaseManager.shared.sendFriendRequest(friendUsername: friendUsername) { (success) in
                
                if success {
                    self.navigationController?.popViewController(animated: true)
                }
                else {
                    print("failed to add friend")
                }
            }
        }
    }
    
}
