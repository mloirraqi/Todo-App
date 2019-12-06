//
//  AddTaskVC.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/29/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import UIKit
import SwiftDate

class AddTaskVC: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descTextField: UITextView!
    @IBOutlet weak var prioritySegControl: UISegmentedControl!
    @IBOutlet weak var assignFriends: UIButton!
    @IBOutlet weak var dueDate: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerDone: UIView!
    @IBOutlet weak var statusSegControl: UISegmentedControl!
    
    var task: Task?
    var newAssignedTo = [DBUser]()
    
    var dueDateString: String?
    
    lazy var canEdit: Bool = {
        return task?.createdBy == task?.assignedTo ? true : false
    }()
    
    //View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descTextField.layer.borderWidth = 1
        descTextField.layer.borderColor = UIColor.lightGray.cgColor
        descTextField.layer.cornerRadius = 4
        
        titleTextField.layer.masksToBounds = true
        titleTextField.layer.borderColor = UIColor.lightGray.cgColor
        titleTextField.layer.borderWidth = 1.0
        titleTextField.layer.cornerRadius = 4

        populate()
        disableFields()
    }
    
    //IBActions
    @IBAction func saveButton(_ sender: Any) {
        
        var isRemovedFromMe = true
        
        var errors = [String]()
        
        if (titleTextField.text?.count ?? 0) <= 0 {
            errors.append("title")
        }
        
        if (descTextField.text?.count ?? 0) <= 0 {
            errors.append("description")
        }

        if (dueDateString?.count ?? 0) <= 0 {
            errors.append("due date")
        }
        
        
        if newAssignedTo.count > 0 {
            for assigned in newAssignedTo {
                
                let priority = prioritySegControl.selectedSegmentIndex
                                
                guard let title = titleTextField.text, title.count > 0,
                    let desc = descTextField.text,
                    let date = dueDateString
                    else { break }
                
                let status = statusSegControl.selectedSegmentIndex
                
                if task != nil, let id = self.task?.id, assigned.username! == task!.assignedTo { //update
                    
                    isRemovedFromMe = false
                    
                    let createdBy = task!.createdBy!

                    FirebaseManager.shared.updateTask(id: id, task: title,
                                                      desc: desc,
                                                      priority: priority,
                                                      createdBy: createdBy,
                                                      assignedTo: assigned.username!,
                                                      due: date,
                                                      status: status, star: (task?.star ?? 0))
                } else { //add
                    
                    let createdBy = FirebaseManager.shared.dbUser.username!

                    FirebaseManager.shared.addTask(task: title, desc: desc,
                                                   priority: priority,
                                                   createdBy: createdBy,
                                                   assignedTo: assigned.username!,
                                                   due: date,
                                                   status: status, star: (task?.star ?? 0))
                }

            }
            
            //delete.. I edit a task and assign to someone else, and remove me
            if task != nil && isRemovedFromMe {
                print("delete assignement from me")
                FirebaseManager.shared.removeTask(id: task!.id)
            }

        }
        
        else {
            print("assigned to is not set")
            errors.append("assignee")
        }
        
        //show errors if any
        let errCount = errors.count
        if errCount > 0 {
            let errorsString = errors.joined(separator: errCount > 2 ? ", " : " & ")
            let errMsg = "Please set \(errorsString) to save the task."
            
            let alert = UIAlertController(title: "Missing details", message: errMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
        
        
    }
    
    @IBAction func dueDatePressed(_ sender: Any) {
        datePicker.isHidden = false
        datePickerDone.isHidden = false
    }

    @IBAction func donePickerPressed(_ sender: Any) {
        datePicker.isHidden = true
        datePickerDone.isHidden = true
        
        let due = datePicker.date
        dueDateString = due.toFormat(Constants.dateFormat)
        
        self.dueDate.setTitle("Due by " + dueDateString!, for: .normal)

    }
    
    //Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segue.addTaskToFriend, let vc = segue.destination as? FriendsVC {
            vc.mode = .assignFriends
            vc.delegate = self
        }
    }
    
}

extension AddTaskVC: UITextFieldDelegate, UITextViewDelegate {
    
    private func populate() {
        
        assignFriends.setTitle("Select assignee?", for: .normal)

        
        guard let task = task else { return }
        
        title = "Edit Task"
        
        titleTextField.text = task.title
        descTextField.text = task.desc
        
        prioritySegControl.selectedSegmentIndex = task.priority
        
        if let date = task.dueDate {
            dueDateString = date
            self.dueDate.setTitle("Due by " + dueDateString!, for: .normal)
        }
        
        if let assigned = task.assignedTo {
            assignFriends.setTitle("Assigned to \(assigned)", for: .normal)
            
            FirebaseManager.shared.fetchUserFromDB(username: assigned) { (currentlyAssigned) in
                let contains = self.newAssignedTo.filter { $0.username == currentlyAssigned.username }
                if contains.count <= 0 {
                    self.newAssignedTo.append(currentlyAssigned)
                }
            }
            
        }
        
    }
    
    private func disableFields() {
        titleTextField.isEnabled        = canEdit
        descTextField.isEditable        = canEdit
        assignFriends.isEnabled         = canEdit
        prioritySegControl.isEnabled    = canEdit
        dueDate.isEnabled               = canEdit
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleTextField {
            descTextField.becomeFirstResponder()
        }
        return false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
}

extension AddTaskVC: AddFriendsSelected {
    
    func friendsListDidSelect(selectedFriends: [DBUser]) {
        self.newAssignedTo = selectedFriends
        let assignedArray = selectedFriends.map{ $0.username! }
        let assigned = assignedArray.joined(separator: ", ")
        assignFriends.setTitle("Assigned to \(assigned)", for: .normal)

    }
    
}
