//
//  ViewTaskVC.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/30/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import UIKit

class ViewTaskVC: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var dueLabel: UILabel!
    @IBOutlet weak var assignedTo: UILabel!
    
    @IBOutlet weak var addCommentButton: UIButton!
    @IBOutlet weak var commentsTableView: UITableView!
    
    var task: Task?
    var comments: [Comments]? {
        didSet {
            commentsTableView.reloadData()
        }
    }

    //View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        populate()
        
        let shadowPath = UIBezierPath(rect: backgroundView.bounds)

        backgroundView.layer.masksToBounds = false
        backgroundView.layer.shadowOffset = CGSize(width: -10, height: 0)
        backgroundView.layer.cornerRadius = 12
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowRadius = 16
        backgroundView.layer.shadowPath = shadowPath.cgPath
        backgroundView.layer.shadowOpacity = 0.15

        backgroundView.backgroundColor = .white

    }
    
    //Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segue.addToEditTask, let addTaskVC = segue.destination as? AddTaskVC {
            addTaskVC.task = self.task
        }
    }
    
    @IBAction func addPressed(_ sender: UIButton) {
        addComment()
    }
}

//Helpers
extension ViewTaskVC {
    
    private func populate() {
        populateTask()
        populateComments()
    }
    
    private func populateTask() {
        
        guard let t = task else { return }

        FirebaseManager.shared.task(id: t.id) { (task) in
                 
                 guard let task = task else {
                     self.navigationController?.popViewController(animated: true)
                     return
                 }

                 self.titleLabel.text = task.title
                 self.descLabel.text = task.desc
                 
                 var priority = "Medium"
                 
                 if task.priority == 0 {
                     priority = "High"
                 } else if task.priority == 2 {
                     priority = "Low"
                 }
                 
                 var status = "To Do"
                 
                 if task.status == 1 {
                     status = "Done"
                 }
                 
                 self.priorityLabel.text = "Priority: \(priority)"
                 self.statusLabel.text = "Status: \(status)"

                 if let date = task.dueDate {
                     self.dueLabel.text = "Due by \(date)"
                 }
                 
                 if let assigned = task.assignedTo, let creator = task.createdBy {
                     if assigned == creator {
                         self.assignedTo.text = "Created by \(creator)"
                     } else {
                         self.assignedTo.text = "Assigned to \(assigned) & Created by \(creator)"
                     }
                 }
             }
    }
    
    private func populateComments() {
        
        guard let t = task else { return }

        FirebaseManager.shared.comments(taskId: t.id) { (comments) in
            self.comments = comments.sorted(by: { (t1, t2) -> Bool in
                let t1date = t1.date.toDate(Constants.dateFormat)
                let t2date = t2.date.toDate(Constants.dateFormat)
                
                return (t2date?.isBeforeDate(t1date!, granularity: Calendar.Component.second))!
            })
        }
        
    }
    
    private func addComment() {
        
        guard let t = task else { return }
        
        showAlertForInfo(text: "comment") { (newComment) in
            
            FirebaseManager.shared.addComment(text: newComment, taskId: t.id)
            
            let msg = "Your new comment is added successfully"
            self.showAlert(title: "Comment", msg: msg)
            
        }
        
    }
    
    private func showAlertForInfo(text: String, completion: @escaping (String) -> ()) {
        
        let alert = UIAlertController(title: "New \(text)", message: "Please input new value", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default) { (alertAction) in
            if let textField = alert.textFields?[0],
                let text = textField.text, text.count > 0 {
                completion(text)
            }
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Enter your \(text)"
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

//Tableview
extension ViewTaskVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsCell") as! CommentsCell
        
        if let comment = comments?[indexPath.row] {
            cell.commentLabel.text = comment.text
            cell.dateLabel.text = comment.date
            cell.byLabel.text = comment.createdBy
        }
        
        return cell
    }

}


public class CommentsCell: UITableViewCell {
    
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var byLabel: UILabel!
    
}
