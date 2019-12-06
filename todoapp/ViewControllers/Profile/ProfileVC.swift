//
//  ProfileVC.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/30/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import UIKit
import Firebase

class ProfileVC: UIViewController {
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var emaillabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var friendsButton: UIButton!
    @IBOutlet weak var changePhotoButton: UIButton!
    
    @IBOutlet weak var editEmailButton: UIButton!
    @IBOutlet weak var editNameButton: UIButton!
    @IBOutlet weak var editUsernameButton: UIButton!
    
    var user: DBUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populate()
        
        //Buttons
        let hide                        = user != nil
        logoutButton.isHidden           = hide
        friendsButton.isHidden          = hide
        changePhotoButton.isHidden      = hide
        editEmailButton.isHidden        = hide
        editUsernameButton.isHidden     = true //We cannot change username
        editNameButton.isHidden         = true //We are not chaning name as well

        //Photo
        changePhotoButton.layer.cornerRadius = 20
        photoView.contentMode = .scaleAspectFill
        photoView.layer.cornerRadius = 70

           
    }
    
    //IBOutlets
    @IBAction func logoutPressed(_ sender: Any) {
        FirebaseManager.shared.logout()
    }
    
    @IBAction func changePhotoPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Pick profile photo", message: "Select source", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerController.SourceType.camera
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Library", style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.allowsEditing = true
                imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        
        present(alert, animated: true)
    }
    
    @IBAction func editEmailPressed(_ sender: Any) {
        showAlertForInfo(text: "email") { (newEmail) in
            FirebaseManager.shared.updateEmail(newEmail: newEmail) { success, errMsg in
                
                let msg = success ? "Email is changed successfully" : (errMsg ?? "Unable to update. Something went wrong")
                self.showAlert(title: "Email", msg: msg)
                
                if success {
                    self.emaillabel.text = newEmail
                }
                
            }
        }
    }
    
    @IBAction func editUsernamePressed(_ sender: Any) {
        
    }
    
    @IBAction func editNamePressed(_ sender: Any) {
        
        showAlertForInfo(text: "name") { (newName) in
            
            FirebaseManager.shared.updateName(newName: newName)
            
            let msg = "Name is changed successfully"
            self.showAlert(title: "Name", msg: msg)
            
            self.nameLabel.text = newName
        }
    }
    
    private func showAlertForInfo(text: String, completion: @escaping (String) -> ()) {
        
        let alert = UIAlertController(title: "Edit \(text)", message: "Please input new value", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default) { (alertAction) in
            if let textField = alert.textFields?[0],
                let text = textField.text, text.count > 0 {
                completion(text)
            }
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Enter your new \(text)"
        }
        
        alert.addAction(action)
        present(alert, animated:true)
    }
    
    private func showAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}

extension ProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func populate() {
        
        var username = String()
        
        if let un = user?.username { //friend
            FirebaseManager.shared.fetchUserFromDB(username: un) { (user) in
                self.emaillabel.text = user.email
                self.nameLabel.text = user.name
                self.usernameLabel.text = user.username
                self.createdAtLabel.text = user.createdAt
            }
            
            username = un
        }
        else { //me
            let user = FirebaseManager.shared.dbUser
            
            self.emaillabel.text = user.email
            self.nameLabel.text = user.name
            self.usernameLabel.text = user.username
            self.createdAtLabel.text = user.createdAt
            
            username = user.username!
        }
        
        
        //Set Photo
        FirebaseManager.shared.fetchPhoto(username: username) { (img) in
            if let image = img {
                self.photoView.image = image
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            photoView.image = pickedImage
            uploadPhotoOnBackend(pickedImage)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func uploadPhotoOnBackend(_ image: UIImage) {
        FirebaseManager.shared.saveMyPhoto(image: image)
    }
}
