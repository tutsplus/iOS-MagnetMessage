//
//  SignInViewController.swift
//  MessageMe
//
//  Created by Bart Jacobs on 26/11/15.
//  Copyright © 2015 Magnet. All rights reserved.
//

import UIKit
import MagnetMax

protocol SignInViewControllerDelegate {
    
    func controller(controller: SignInViewController, didSignInWithUser user: MMUser)
    
}

class SignInViewController: UIViewController {
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var delegate: SignInViewControllerDelegate?
    
    var hasAccount = true
    
    // MARK: -
    // MARK: View Life Cycle
    override func viewDidLoad() {
        if hasAccount {
            signInButton.setTitle("Sign In", forState: UIControlState.Normal)
        } else {
            signInButton.setTitle("Create Account", forState: UIControlState.Normal)
        }
    }
    
    // MARK: -
    // MARK: Actions
    @IBAction func signIn(sender: UIButton) {
        guard let username = usernameTextField.text else {
            showAlertWithTitle("Username Required", message: "Enter a valid username.")
            return
        }
        
        guard let password = passwordTextField.text else {
            showAlertWithTitle("Password Required", message: "Enter a valid password.")
            return
        }
        
        guard !username.isEmpty && !password.isEmpty else {
            showAlertWithTitle("Error", message: "Enter a valid username and password.")
            return;
        }
        
        // Create Credential
        let credential = NSURLCredential(user: username, password: password, persistence: .None)
        
        if hasAccount {
            signInWithCredential(credential)
        } else {
            createAccountWithCredential(credential)
        }
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
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
    
    private func createAccountWithCredential(credential: NSURLCredential) {
        // Create User
        let user = MMUser()
        
        // Configure User
        user.userName = credential.user
        user.password = credential.password
        
        // Register User
        user.register({ (user) -> Void in
            // Sign User In
            self.signInWithCredential(credential)
            
            }) { (error) -> Void in
                print(error)
                
                if error.code == 409 {
                    // Account Already Exists
                    self.signInWithCredential(credential)
                    
                } else {
                    // Notify User
                    self.showAlertWithTitle("Error", message: "We were unable to create an account. Please try again.")
                }
        }
    }

    private func signInWithCredential(credential: NSURLCredential) {
        MMUser.login(credential, success: { () -> Void in
            MagnetMax.initModule(MMX.sharedInstance(), success: { () -> Void in
                // Store Username in User Defaults
                NSUserDefaults.standardUserDefaults().setObject(credential.user, forKey: "username")
                
                // Notify Delegate
                self.delegate?.controller(self, didSignInWithUser: MMUser.currentUser()!)
                
                // Pop View Controller
                self.dismissViewControllerAnimated(true, completion: nil)
                
                }, failure: { (error) -> Void in
                    print(error)
                    
                    // Notify User
                    self.showAlertWithTitle("Error", message: "We were unable to sign you in. Please make sure that the credentials you entered are correct.")
            })
            
            }) { (error) -> Void in
                print(error)
                
                // Notify User
                self.showAlertWithTitle("Error", message: "We were unable to sign you in. Please make sure that the credentials you entered are correct.")
        }
    }
    
}
