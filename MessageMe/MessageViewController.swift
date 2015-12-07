//
//  MessageViewController.swift
//  MessageMe
//
//  Created by Bart Jacobs on 26/11/15.
//  Copyright © 2015 Magnet. All rights reserved.
//

import UIKit
import MagnetMax
import CoreLocation

class MessageViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, SignInViewControllerDelegate, RecipientsViewControllerDelegate {
    
    let SegueSignIn = "SegueSignIn"
    let SegueRecipients = "SegueRecipients"
    let SegueCreateAccount = "SegueCreateAccount"
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var buttonsView: UIView!
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var recipientsTextField: UITextField!
    
    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    
    var recipients: [MMUser] = []
    
    var user: MMUser? {
        didSet {
            updateView()
        }
    }
    
    // MARK: -
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MMX.start()
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "didReceiveMessage:", name: MMXDidReceiveMessageNotification, object: nil)
        
        setupView()
    }
    
    // MARK: -
    // MARK: Prepare for Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueSignIn {
            let signInViewController = segue.destinationViewController as! SignInViewController
            
            // Configure Sign In View Controller
            signInViewController.hasAccount = true
            signInViewController.delegate = self
            
        } else if segue.identifier == SegueCreateAccount {
            let signInViewController = segue.destinationViewController as! SignInViewController
            
            // Configure Sign In View Controller
            signInViewController.hasAccount = false
            signInViewController.delegate = self
            
        } else if segue.identifier == SegueRecipients {
            let recipientsViewController = segue.destinationViewController as! RecipientsViewController
            
            // Configure Recipients View Controller
            recipientsViewController.delegate = self
        }
    }
    
    // MARK: -
    // MARK: Location Manager Delegate Methods
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager?.requestLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            // Update Current Location
            currentLocation = location
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        locationSwitch.setOn(false, animated: true)
    }
    
    // MARK: -
    // MARK: Text Field Delegate Methods
    func textFieldDidBeginEditing(textField: UITextField) {
        performSegueWithIdentifier(SegueRecipients, sender: self)
    }
    
    // MARK: -
    // MARK: Sign In View Controller Delegate Methods
    func controller(controller: SignInViewController, didSignInWithUser user: MMUser) {
        self.user = user
    }
    
    // MARK: -
    // MARK: Recipients View Controller Delegate Methods
    func controller(controller: RecipientsViewController, didSelectRecipients recipients: [MMUser]) {
        // Update Recipients
        self.recipients = recipients
        
        var recipientsAsStrings: [String] = []
        
        for recipient in recipients {
            recipientsAsStrings.append(recipient.userName)
        }
        
        // Update Text Field
        recipientsTextField.text = recipientsAsStrings.joinWithSeparator(", ")
    }
    
    // MARK: -
    // MARK: View Methods
    func setupView() {
        updateView()
    }
    
    func updateView() {
        let signedIn = (user != nil)
        buttonsView.hidden = signedIn
        messageView.hidden = !signedIn
    }
    
    // MARK: -
    // MARK: Actions
    @IBAction func done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func sendMessage(sender: UIButton) {
        guard let messageAsString = messageTextField.text else {
            showAlertWithTitle("Message Required", message: "You need to enter a message.")
            return
        }
        
        guard recipients.count > 0 else {
            showAlertWithTitle("Recipients Required", message: "You need to have at least one recipient.")
            return
        }
        
        let toRecipients = Set(recipients)
        var contents: [String : String] = ["message" : messageAsString]
        
        if let location = currentLocation {
            let coordinate = location.coordinate
            contents["location"] = "\(coordinate.latitude),\(coordinate.longitude)"
        }
        
        let message = MMXMessage(toRecipients: toRecipients, messageContent: contents)
        message.sendWithSuccess({ (invalidUsernames) -> Void in
            self.showAlertWithTitle("Message Sent", message: "Your message was successfully sent.")
            
            }) { (error) -> Void in
                print(error)
        }
    }
    
    @IBAction func locationSwitchDidChange(sender: UISwitch) {
        if sender.on {
            requestLocation()
        }
    }
    
    // MARK: -
    // MARK: Notification Handling
    func didReceiveMessage(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        guard let message = userInfo[MMXMessageKey] as? MMXMessage else { return }
        
        // Send Delivery Confirmation
        message.sendDeliveryConfirmation()
        
        print(message)
    }
    
    // MARK: -
    // MARK: Helper Methods
    private func showAlertWithTitle(title: String, message: String) {
        // Initialize Alert Controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        // Configure Alert Controller
        alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        
        // Present Alert Controller
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func requestLocation() {
        if locationManager == nil {
            // Initialize Location Manager
            let locationManager = CLLocationManager()
            
            // Configure Location Manager
            locationManager.delegate = self
            
            // Set Location Manager
            self.locationManager = locationManager
        }
        
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            // Request Location
            locationManager?.requestLocation()
        } else {
            // Ask User for Permission
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
}
