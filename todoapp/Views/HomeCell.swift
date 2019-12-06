//
//  HomeCell.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/30/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import UIKit

class HomeCell: UITableViewCell {

    @IBOutlet weak var taskTitle: UILabel!
    @IBOutlet weak var taskDue: UILabel!
    @IBOutlet weak var taskInfo: UILabel!
    
    @IBOutlet weak var starButton: UIButton!
    
    var starSelected: ((Bool) -> ())?
    
    @IBAction func starPressed(_ sender: Any) {
        starButton.isSelected = !starButton.isSelected
        starSelected?(starButton.isSelected)
    }
    
}
