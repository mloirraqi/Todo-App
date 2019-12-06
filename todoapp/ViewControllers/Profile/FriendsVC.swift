//
//  FriendsVC.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/30/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import UIKit

protocol AddFriendsSelected: class {
    func friendsListDidSelect(selectedFriends: [DBUser])
}

enum AddFriendMode {
    case assignFriends
    case viewFriends
}

class FriendsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var friendsSegControl: UISegmentedControl!
    @IBAction func sortButton(_ sender: Any) {
    }
    
    weak var delegate: AddFriendsSelected?
    var mode: AddFriendMode = .viewFriends
    var selectedFriends = [DBUser]()
    var friends = [DBUser]()
    
    //View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if mode == .assignFriends {
            let backButton = UIBarButtonItem()
            backButton.title = "Done"
            self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        populate()
    }
    
    private func setupForModeAndSegment() {
        
        if mode == .assignFriends && friendsSegControl.selectedSegmentIndex == 0 {
            tableView.allowsMultipleSelection = true
        } else {
            tableView.allowsSelection = true
        }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Selected Friends
        if mode == .assignFriends, let indexPaths = tableView.indexPathsForSelectedRows {
            for indexPath in indexPaths {
                if indexPath.section == 0 {
                    let me = FirebaseManager.shared.dbUser
                    selectedFriends.append(me)
                } else {
                    selectedFriends.append(friends[indexPath.row])
                }
            }
        }
        
        delegate?.friendsListDidSelect(selectedFriends: selectedFriends)
    }
    
    @IBAction func segControlChanged(_ sender: Any) {
        populate()
    }
    
    func populate() {
        
        self.friends.removeAll()
        self.selectedFriends.removeAll()

        if self.friendsSegControl.selectedSegmentIndex == 0 {
            FirebaseManager.shared.fetchMyFriends { (friendsList) in
                
                self.friends = friendsList
                
//                if self.mode == .assignFriends {
//
//                    var me = FirebaseManager.shared.dbUser
//                    me.name = "--- " + me.name! + " (ME) ---"
//                    self.friends.insert(me, at: 0)
//                }
                
                self.tableView.reloadData()
            }
            
        }
        else {
            FirebaseManager.shared.fetchMyFriendRequests { (friendsList) in
                self.friends = friendsList
                self.tableView.reloadData()
            }
        }
        
        setupForModeAndSegment()
    }
    
}

extension FriendsVC: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if self.friendsSegControl.selectedSegmentIndex == 0 && self.mode == .assignFriends {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.friendsSegControl.selectedSegmentIndex == 0 && self.mode == .assignFriends {
            if section == 0 {
                return 1
            }
        }
        return friends.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var user = DBUser()

        if self.friendsSegControl.selectedSegmentIndex == 0 && self.mode == .assignFriends {
            if indexPath.section == 0 {
                user = FirebaseManager.shared.dbUser
            } else {
                user = friends[indexPath.row]
            }
            
        } else {
             user = friends[indexPath.row]
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendsCell") as! FriendsCell
        
        cell.nameLabel.text = user.name
        cell.usernameLabel.text = user.username
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if friendsSegControl.selectedSegmentIndex == 1 {
            let friendUsername = friends[indexPath.row].username!
            
            FirebaseManager.shared.addFriend(friendUsername: friendUsername) { (success) in
                
                if success {
                    self.friendsSegControl.selectedSegmentIndex = 0
                    self.populate()
                }
                else {
                    print("failed to add friend")
                }
            }
        }
        
        else if friendsSegControl.selectedSegmentIndex == 0 && mode == .viewFriends {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let profileViewController = storyBoard.instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
            profileViewController.user = friends[indexPath.row]
            navigationController?.pushViewController(profileViewController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if self.friendsSegControl.selectedSegmentIndex == 0 && self.mode == .assignFriends {
                return section == 0 ? "Me" : "Friends"
        }
        
        return nil
    }
}

class FriendsCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
}
