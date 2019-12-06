//
//  ViewController.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/29/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import UIKit

class LoginVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    //View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //emailTextField.text = "asdf@asdf.com"
        //passwordTextField.text = "123123"
        
        FirebaseManager.shared.tryLogin { (success) in
            if success {
                Constants.showHome()
            }
        }
        
    }
    
    //IBAction
    @IBAction func loginPressed(_ sender: Any) {
        
        guard let email = emailTextField.text, let password = passwordTextField.text, email.count > 0, password.count > 0 else {
            let alert = UIAlertController(title: "Error", message: "Email and Password cannot be empty.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        
        FirebaseManager.shared.login(email: email, password: password) { error in
            print(error)
            let alert = UIAlertController(title: "Unable to Login", message: error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            return
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            passwordTextField.resignFirstResponder()
        }
        return false
    }

}

