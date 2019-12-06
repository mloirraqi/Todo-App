//
//  HomeVC.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/29/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import UIKit

enum Sorting {
    case dueDate
    case stars
    case priority
}

class HomeVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tasksSegControl: TasksSegmentedControl!
    @IBOutlet weak var showCompSwitch: UISwitch!
    @IBOutlet weak var sortButton: UIButton!
    
    var tasks = [Task]()
    
    //Helpers
    var sortBy: Sorting = .dueDate {
        didSet {
            reload()
        }
    }
    
    func sortTasksData() {
        
         let sort = sortBy //else { return }
        
        switch sort {
        case .dueDate:
            tasks = tasks.sorted(by: { (t1, t2) -> Bool in
                let t1date = t1.dueDate?.toDate(Constants.dateFormat)
                let t2date = t2.dueDate?.toDate(Constants.dateFormat)
                
                return (t2date?.isAfterDate(t1date!, granularity: Calendar.Component.second))!
            })
        case .stars:
            tasks = tasks.sorted(by: { (t1, t2) -> Bool in
                return t1.star > t2.star
            })
        case .priority:
            tasks = tasks.sorted(by: { (t1, t2) -> Bool in
                return t1.priority < t2.priority
            })
        }
    }
    
    private func fetchDataForSegment() {
        
        guard let me = FirebaseManager.shared.dbUser.username else { return }
        self.tasks.removeAll()
        
        if tasksSegControl.selectedSegmentIndex == 0 {
            FirebaseManager.shared.tasks(keyname:  "assignedTo", value: me) { (response) in
                if let tasksData = response {
                    self.tasks = tasksData
                    self.reload()
                }
            }
        }
        else {
            FirebaseManager.shared.tasks(keyname:  "createdBy", value: me) { (response) in
                if let tasksData = response {
                    self.tasks = tasksData
                    self.tasks.removeAll(where: { $0.assignedTo == me})
                    self.reload()
                }
            }
        }

    }
    
    func reload() {
        if showCompSwitch.isOn { //hide enabled
            tasks = tasks.filter { $0.status == 0 }
        }
        sortTasksData()
        tableView.reloadData()
    }
    
    //Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //sortButton.layer.borderWidth = 1
        sortButton.layer.borderColor = UIColor.lightGray.cgColor
        sortButton.layer.cornerRadius = 4
        
        showCompSwitch.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        tasksSegControl.layer.cornerRadius = 0
        
        FirebaseManager.shared.removeAuthListner()
        self.fetchDataForSegment()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
        if segue.identifier == Constants.Segue.listToViewTask,
            let viewTaskVC = segue.destination as? ViewTaskVC,
            let row = tableView.indexPathForSelectedRow?.row {
            viewTaskVC.task = self.tasks[row]
        }
        
    }
    
    //IbActions
    @IBAction func sortButtonPressed(_ sender: Any) {
        let sheet = UIAlertController(title: "Sort", message: "Select a sorting method", preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Due Date", style: .default, handler: { _ in
            self.sortBy = .dueDate
        }))
        
        sheet.addAction(UIAlertAction(title: "Priority", style: .default, handler: { _ in
            self.sortBy = .dueDate
            self.sortBy = .priority
        }))
        
        sheet.addAction(UIAlertAction(title: "Star", style: .default, handler: { _ in
            self.sortBy = .dueDate
            self.sortBy = .stars
        }))
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        
        self.present(sheet, animated: true)
    }
    
    @IBAction func showCompToggled(_ sender: Any) {
        self.fetchDataForSegment()
    }
    
    @IBAction func tasksSegControlChanged(_ sender: Any) {
        self.fetchDataForSegment()
    }
    
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeCell") as! HomeCell
        
        let task = self.tasks[indexPath.row]
        
        cell.taskTitle.text = task.title
        cell.taskDue.text = task.dueDate
        
        var priority = "Normal"
        
        if task.priority == 0 {
            priority = "High"
        } else if task.priority == 2 {
            priority = "Low"
        }
        
        cell.taskInfo.text = priority
        
        cell.starButton.isSelected = task.star == 1 ? true : false
        
        cell.starSelected = { (selected) in
            self.updateStar(selected, task)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let task = tasks[indexPath.row]
            FirebaseManager.shared.removeTask(id: task.id)
            self.tasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func updateStar(_ selected: Bool, _ task: Task) {
        FirebaseManager.shared.updateTask(id: task.id, task: task.title, desc: task.desc ?? "", priority: task.priority, createdBy: task.createdBy!, assignedTo: task.assignedTo!, due: task.dueDate!, status: task.status, star: selected ? 1 : 0)
    }
    
}


//Segmented Control Customization
class TasksSegmentedControl: UISegmentedControl {
    
    let textColor =  #colorLiteral(red: 0.2008180022, green: 0.3733796477, blue: 0.764033258, alpha: 1)
    let bgColor = UIColor.white
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let defaultAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: textColor.withAlphaComponent(0.7)
        ]
        let selectedAttributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: textColor
        ]
        setTitleTextAttributes(defaultAttributes, for: .normal)
        setTitleTextAttributes(selectedAttributes, for: .selected)
        
        backgroundColor = bgColor
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 0
    }
}
