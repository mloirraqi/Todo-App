//
//  SignupVC.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/29/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import UIKit

class SignupVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var Username: UITextField!
    @IBOutlet weak var displayNameTextField: UITextField!
    
    //View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //IBAcions
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func registerPressed(_ sender: Any) {
        
        guard let email = emailTextField.text, email.count > 0,
            let password = passwordTextField.text, password.count > 0,
            let confirm = confirmTextField.text, confirm.count > 0,
            let username = Username.text, username.count > 0,
            let name = displayNameTextField.text, name.count > 0
            else {
                let alert = UIAlertController(title: "Unable to Sign Up", message: "Please fill all information.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                return }
        
        if password != confirm {
            let alert = UIAlertController(title: "Error", message: "Password and Confirm Password do not match.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        
        FirebaseManager.shared.signUp(email: email, password: password, name: name, username: username) { (success) in
            if success {
                print(success ? "registered successfully" : "wow")
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        }
        else if textField == passwordTextField {
            confirmTextField.becomeFirstResponder()
        }
        else if textField == confirmTextField {
            displayNameTextField.becomeFirstResponder()
        }
        else if textField == displayNameTextField {
            Username.becomeFirstResponder()
        }
        else if textField == Username {
            Username.resignFirstResponder()
        }
        return false
    }
}
