//
//  RecipientsViewController.swift
//  MessageMe
//
//  Created by Bart Jacobs on 26/11/15.
//  Copyright © 2015 Magnet. All rights reserved.
//

import UIKit
import MagnetMax

protocol RecipientsViewControllerDelegate {
    
    func controller(controller: RecipientsViewController, didSelectRecipients recipients: [MMUser])
    
}

class RecipientsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    let SearchCell = "SearchCell"
    
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: RecipientsViewControllerDelegate?
    
    var users: [MMUser] = []
    
    // MARK: -
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: SearchCell)
    }
    
    // MARK: -
    // MARK: Table View Data Source Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return users.count > 0 ? 1 : 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SearchCell, forIndexPath: indexPath)
        
        // Fetch User
        let user = users[indexPath.row]
        
        // Configure Cell
        cell.textLabel?.text = user.userName
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // MARK: -
    // MARK: Search Bar Delegate Methods
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.characters.count > 3 else { return }
        
        MMUser.searchUsers("userName:\(searchText)*", limit: 50, offset: 0, sort: "userName:asc", success: { (users) -> Void in
            self.users = users
            self.tableView.reloadData()
            
            }) { (error) -> Void in
                print(error)
        }
    }
    
    // MARK: -
    // MARK: Actions
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        // Fetch Selection
        var selection: [MMUser] = []
        
        if let indexPaths = tableView.indexPathsForSelectedRows {
            for indexPath in indexPaths {
                selection.append(users[indexPath.row])
            }
        }
        
        // Notify Delegate
        delegate?.controller(self, didSelectRecipients: selection)
        
        // Dismiss View Controller
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
