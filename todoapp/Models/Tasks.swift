//
//  Tasks.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/30/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import Foundation
import UIKit

struct Task: Codable {
    var id: String
    var assignedTo: String?
    var createdBy: String?
    var desc: String?
    var dueDate: String?
    var priority: Int
    var status: Int
    var title: String
    var star: Int
}

