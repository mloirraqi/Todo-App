//
//  FirebaseManager.swift
//  todoapp
//
//  Created by Mohamed Loirraqi on 11/29/2019.
//  Copyright © 2019 mloi. All rights reserved.
//

import Foundation
import Firebase
import SwiftDate

class FirebaseManager {
    
    var listenHandler: AuthStateDidChangeListenerHandle?

    var authUser: User?
    var dbUser = DBUser()

    static var shared = FirebaseManager()
    
    let rootRef = Database.database().reference()
    let tasksRef = Database.database().reference().child("tasks")
    let usersRef = Database.database().reference().child("users")
    let friendRef = Database.database().reference().child("friends")
    let fRequestRef = Database.database().reference().child("friend-requests")
    let commentRef = Database.database().reference().child("comments")

    //Auth
    func signUp(email: String, password: String, name: String, username: String, completion: @escaping (Bool) -> ()) {
        
        if (password.count == 0) {
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            print(authResult ?? "auth failed")
            
            if let user = authResult?.user {
                
                let changeRequest = user.createProfileChangeRequest()
                
                changeRequest.displayName = name
                
                changeRequest.commitChanges { error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
                
                self.authUser = user

                //Store in db
                self.addUserInDB(email: email, username: username, name: name)
            }
            
            completion(error == nil ? true : false)
        }
        
    }
    
    func login(email: String, password: String, errorMsg: @escaping (String) -> ()) {
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if error != nil {
                errorMsg(error?.localizedDescription ?? "Auth failed")
            }
        }
        
    }
    
    func tryLogin(completion: @escaping (Bool) -> ()) {
        listenHandler = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let fuser = user {
                self.authUser = fuser
                if let email = user?.email {
                    self.fetchUserFromDBForAuth(email: email) {
                        completion(true)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
        Constants.showLogin()
    }
    
    func removeAuthListner() {
        if let _ = listenHandler {
            Auth.auth().removeStateDidChangeListener(listenHandler!)
        }
    }
    
    //User
    func addUserInDB(email: String, username: String, name: String) {
        
        let newChild = usersRef.child(username)
        
        let date = Date().toFormat(Constants.dateFormat)
        
        newChild.setValue([
            "username": username,
            "name" : name,
            "createDate" : date,
            "email" : email
        ])
        
    }
    
    func fetchUserFromDBForAuth(email: String, completion: @escaping () -> ()) {
        
        usersRef.queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: .value) { (snapshot) in
            
            var dic = snapshot.value as? [String : AnyObject] ?? [:]
            dic = dic.first?.value as? [String : AnyObject]  ?? [:]
            
            self.dbUser.username = dic["username"] as? String
            self.dbUser.name = dic["name"] as? String
            self.dbUser.createdAt = dic["createDate"] as? String
            self.dbUser.email = dic["email"] as? String
            
            completion()
        }

    }
    
    func fetchUserFromDB(username: String, completion: @escaping (DBUser) -> ()) {
        
        usersRef.child(username).observe(.value) { (snapshot) in
        
            let dic = snapshot.value as? [String : AnyObject] ?? [:]

            var dbUser = DBUser()
            
            dbUser.username = dic["username"] as? String
            dbUser.name = dic["name"] as? String
            dbUser.createdAt = dic["createDate"] as? String
            dbUser.email = dic["email"] as? String
            
            completion(dbUser)
        }

    }
    
    //User-Update
    func updateEmail(newEmail: String, completion: @escaping (Bool, String?) -> ()) {
                
        self.authUser?.updateEmail(to: newEmail, completion: { (error) in
            
            let me = FirebaseManager.shared.dbUser
            let username = me.username!
            
            if error != nil { //error
                completion(false, error?.localizedDescription)
            } else { //success
                let newChild = self.usersRef.child(username)
                
                newChild.setValue([
                    "username": username,
                    "name" : me.name!,
                    "createDate" : me.createdAt!,
                    "email" : newEmail
                ])
                
                self.dbUser = DBUser(name: me.name!, email: newEmail, username: username, createdAt: me.createdAt!)
                
                completion(true, nil)
            }
        })
    }
    
    func updateUsername(newUsername: String) {
        
        let me = FirebaseManager.shared.dbUser
        
        //delete old
        let oldChild = usersRef.child(me.username!)
        oldChild.removeValue()
        
        //add new
        let newChild = usersRef.child(newUsername)
        
        newChild.setValue([
            "username": newUsername,
            "name" : me.name!,
            "createDate" : me.createdAt!,
            "email" : me.email!
        ])
        
        self.dbUser = DBUser(name: me.name!, email: me.email!, username: newUsername, createdAt: me.createdAt!)

    }
    
    func updateName(newName: String) {
        
        let me = FirebaseManager.shared.dbUser

        let newChild = self.usersRef.child(me.username!)
        
        newChild.setValue([
            "username": me.username!,
            "name" : newName,
            "createDate" : me.createdAt!,
            "email" : me.email!
        ])
        
        self.dbUser = DBUser(name: newName, email: me.email!, username: me.username!, createdAt: me.createdAt!)
    }
    
    func addComment(text: String, taskId: String) {

        let newChild = commentRef.child(taskId).childByAutoId()
        let date = Date().toFormat(Constants.dateFormat)

        let username = dbUser.username!
        
        newChild.setValue([
            "text" : text,
            "createdBy" : username,
            "date" : date
        ])
    }
    
    func comments(taskId: String, completion: @escaping ([Comments]) -> ()) {
                
        commentRef.child(taskId).observe(.value) { (snapshot) in
        
            let dic = snapshot.value as? [String : AnyObject] ?? [:]

            var comments = [Comments]()
            
            for (key,value) in dic {
                
                let date = value["date"]            as? String
                let by = value["createdBy"]         as? String
                let text = value["text"]            as? String

                
                let comment = Comments(id: key, date: date ?? "", createdBy: by ?? "", text: text ?? "")
                comments.append(comment)
            }
            
            completion(comments)
        }
    }
    
    //Tasks
    func tasks(keyname: String, value: String, completion: @escaping ([Task]?) -> ()) {
        
        tasksRef.removeAllObservers()
        
        tasksRef.queryOrdered(byChild: keyname).queryEqual(toValue: value).observe(.value) { (snapshot) in
            
            let dic = snapshot.value as? [String : AnyObject] ?? [:]
            print(dic)
            
            var tasks = [Task]()
            
            for (key,value) in dic {
                
                let assignedTo = value["assignedTo"]    as? String
                let createdBy = value["createdBy"]      as? String
                let desc = value["desc"]                as? String
                let dueDate = value["dueDate"]          as? String
                let status = value["status"]            as! Int
                let star = value["star"]                as! Int

                let priority = value["priority"]        as! Int
                let title = value["title"]              as! String

                let task = Task(id: key, assignedTo: assignedTo, createdBy: createdBy, desc: desc, dueDate: dueDate, priority: priority, status: status, title: title, star: star)
                
                tasks.append(task)
                
            }
            
            completion(tasks)

        }
    }
    
    func addTask(task: String, desc: String, priority: Int, createdBy: String, assignedTo: String, due: String, status: Int, star: Int) {
        
        let newChild = tasksRef.childByAutoId()
        
        newChild.setValue([
            "title" : task,
            "desc" : desc,
            "createdBy" : createdBy,
            "assignedTo" : assignedTo,
            "dueDate" : due,
            "status" : status,
            "star" : star,
            "priority" : priority
        ])
        
    }
    
    func updateTask(id: String, task: String, desc: String, priority: Int, createdBy: String, assignedTo: String, due: String, status: Int, star: Int) {
        
        let newChild = tasksRef.child(id)
        
        
        newChild.setValue([
            "title" : task,
            "desc" : desc,
            "createdBy" : createdBy,
            "assignedTo" : assignedTo,
            "dueDate" : due,
            "status" : status,
            "priority" : priority,
            "star" : star
        ])
        
    }
    
    func removeTask(id: String) {
        let newChild = tasksRef.child(id)
        newChild.removeValue()
    }
    
    func task(id: String, completion: @escaping (Task?) -> ()) {
        
        tasksRef.child(id).observe(.value) { (snapshot) in
            
            let value = snapshot.value as? [String : AnyObject] ?? [:]
            
            if value.count == 0 {
                return completion(nil)
            }
            
            let assignedTo = value["assignedTo"]    as? String
            let createdBy = value["createdBy"]      as? String
            let desc = value["desc"]                as? String
            let dueDate = value["dueDate"]          as? String
            let status = value["status"]            as! Int
            let star = value["star"]                as! Int

            let priority = value["priority"]        as! Int
            let title = value["title"]              as! String
            
            let task = Task(id: id, assignedTo: assignedTo, createdBy: createdBy, desc: desc, dueDate: dueDate, priority: priority, status: status, title: title, star: star)
        
            completion(task)
        }
    }
    
    //Friends
    func addFriend(friendUsername: String, completion: @escaping (Bool) -> ()) {
        
        let myUsername = dbUser.username!
        let myname = dbUser.name!

        let newChild = self.friendRef.child(friendUsername).child(myUsername)
        newChild.setValue(myname)

        fetchUserFromDB(username: friendUsername) { (friend) in
            
            if let fu = friend.username, fu.count > 0, let fn = friend.name, fn.count > 0 { //friend non empty
                
                let newChild = self.friendRef.child(myUsername).child(friendUsername)
                newChild.setValue(fn)
                
                self.removeFriendRequest(friendUsername: friendUsername)

                completion(true)
            }
            else {
                completion(false)
            }
        }
        
    }
    
    func fetchMyFriends(completion: @escaping ([DBUser]) -> ()) {
        
        let myUsername = dbUser.username!
        
        friendRef.child(myUsername).observeSingleEvent(of: .value) { (snapshot) in
        
            let dic = snapshot.value as? [String : AnyObject] ?? [:]

            var friends = [DBUser]()
            
            for (key,value) in dic {
                
                var dbUser = DBUser()
                dbUser.username = key
                dbUser.name = value as? String
                
                friends.append(dbUser)
            }
            
            completion(friends)
        }
        
    }
    
    //Friend Requests
    func sendFriendRequest(friendUsername: String, completion: @escaping (Bool) -> ()) {
        
        let myUsername = dbUser.username!
        let myname = dbUser.name!

        let newChild = self.fRequestRef.child(friendUsername).child(myUsername)
        newChild.setValue(myname)
        
        completion(true)
        
    }
    
    func fetchMyFriendRequests(completion: @escaping ([DBUser]) -> ()) {
        
        let myUsername = dbUser.username!
        
        fRequestRef.child(myUsername).observeSingleEvent(of: .value) { (snapshot) in
        
            let dic = snapshot.value as? [String : AnyObject] ?? [:]

            var friends = [DBUser]()
            
            for (key,value) in dic {
                
                var dbUser = DBUser()
                dbUser.username = key
                dbUser.name = value as? String
                
                friends.append(dbUser)
            }
            
            completion(friends)
        }
        
    }
    
    func removeFriendRequest(friendUsername: String) {
        let myUsername = dbUser.username!
        fRequestRef.child(myUsername).child(friendUsername).removeValue()
    }
    
    //Image
    func fetchPhoto(username: String, completion: @escaping (UIImage?) -> ()) {
        let storageRef = Storage.storage().reference().child(username)
        storageRef.getData(maxSize: 1 * 10240 * 10240) { data, error in
            if let d = data, let image = UIImage(data: d) {
                completion(image)
            } else {
                completion(nil)
            }
        }
    }
    
    func saveMyPhoto(image: UIImage) {
        let me = FirebaseManager.shared.dbUser
        
        let storageRef = Storage.storage().reference().child(me.username!)
        
        if let uploadData = image.jpegData(compressionQuality: 0.5) {
            storageRef.putData(uploadData, metadata: nil) { (meta, error) in
                if error != nil {
                    print("error uploading")
                } else {
                    storageRef.downloadURL(completion: { (url, error) in
                        print(url?.absoluteString ?? "upload url nil")
                    })
                }
            }
        }
    }
    
    
}


extension Collection {
    //Designed for use with Dictionary and Array types
    var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }
}

struct DBUser {
    var name: String?
    var email: String?
    var username: String?
    var createdAt: String?
}
