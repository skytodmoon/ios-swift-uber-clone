/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

//UITextFieldDelegate added to handle keyboard dismissal
class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var `switch`: UISwitch!
    @IBOutlet var driverLabel: UILabel!
    @IBOutlet var riderLabel: UILabel!
    @IBOutlet var signUpButton: UIButton!
    
    var signupState = true
    
    @IBAction func signUp(sender: AnyObject) {
        //basic check to to see if username and password has been entered
        
        if username.text == "" || password.text == "" {
            
            displayAlert("Missing Field(s)", message: "Username and password are required")
        
        } else {

            
            //handle the login by checking the signupState. If it's true (by default, 
            if signupState == true {
                
                //sign up the user to parse. copied from parse docs. Moved the PFUser declaration inside the if true statement since logging in users do not rely on it
                var user = PFUser()
                user.username = username.text
                user.password = password.text
                
                //use the tilde key to avoid using the keyword switch. The switch is set to an "off" state, assuming that Users are riders initally.
                user["isDriver"] = `switch`.on
            
                user.signUpInBackgroundWithBlock {(succeeded: Bool, error: NSError?) -> Void in
                    if let error = error {
                        //instead of using only let (and having to unwrap at the displayAlert), use if let so there's no need to unwrap
                        if let errorString = error.userInfo["error"] as? String {
                            // Show the errorString somewhere and let the user try again.
                    
                            //uses the displayAlert method: passes in a custom string but the error message will be the error message, which is errorString. Since the errorString was cast as NSString, change it to cast as String.
                            //self is used here because its in a closure
                            self.displayAlert("Sign Up Failed", message: errorString)
                        }
                    
                    } else {
                        // Hooray! Let them use the app now.
                        //when the cuser has successfully logged in, check the switch to determine if the cuser is logging in as a driver or a rider
                        
                        //prev, this was user["isDriver"]. however, because it's an AnyObject, it would have to be downcast and unwrapped. Instead, use the variable, switch.on and compare that

                        

                        
                    }
                }

            } else {
                //copied from parse docs
                //unwrapped both the username and password
                PFUser.logInWithUsernameInBackground(username.text!, password: password.text!) {
                    (user: PFUser?, error: NSError?) -> Void in
                    //this translates to unwrap user if we can, or if user exists
                    if let user = user {
                    //if user != nil {
                        //for the login, check if a user object exists since the cuser did not enter if they are a driver or a rider during login.
                        //print(user)
                        //since the isDriver variable was returned, it can be safely unwarpped. user["isDriver"] is usable since the check with if let user was changed. The user object must be downcasted as a boolean
                        if user["isDriver"]! as! Bool == true {
                            //when the the user is successfully logged in, segue to the rider view controller via segue. Later on, check to see if the user is logging in as a rider or a driver. In this case, segue to the driver since the cuser is a driver
                            self.performSegueWithIdentifier("loginDriver", sender: self)
                            
                            
                        } else {
                            
                            //when the the user is successfully logged in, segue to the rider view controller via segue. Later on, check to see if the user is logging in as a rider or a driver
                            self.performSegueWithIdentifier("loginRider", sender: self)
                            
                        }
                        
                        
                        
                        
                        // Do stuff after successful login.
                        //print ("Login succesful")
                        //segue the user if the user has successfully logged in
                        self.performSegueWithIdentifier("loginRider", sender: self)
                        
                        
                    } else {
                        // The login failed. Check error to see why.
                        //similar to the sign up error. Except that the error here needed an ? 
                        if let errorString = error?.userInfo["error"] as? String {
                            // Show the errorString somewhere and let the user try again.
                            
                            //uses the displayAlert method: passes in a custom string but the error message will be the error message, which is errorString. Since the errorString was cast as NSString, change it to cast as String.
                            //self is used here because its in a closure
                            self.displayAlert("Login Failed", message: errorString)
                        }

                        
                    }
                }
                
            }
        }
        
        
    }
    

    @IBOutlet var toggleSignUpButton: UIButton!
    
    
    @IBAction func toggleSignUp(sender: AnyObject) {
        //need to know what state the app is at. Is it at a sign up state or a login state?
        if signupState == true {
            //change the signup Button's title and state
            signUpButton.setTitle("Login", forState: UIControlState.Normal)
            
            //change the toggle sign up button's title and state
            toggleSignUpButton.setTitle("Switch to Sign Up", forState: UIControlState.Normal)
            
            //change the signupState to false since it was initially set to True
            signupState = false
            
            //hide the labels by changing its alpha to 0
            riderLabel.alpha = 0
            driverLabel.alpha = 0
            `switch`.alpha = 0
        } else {
            //reverse the states, the buttons title and label's titles
            //change the signup Button's title and state back to signup
            signUpButton.setTitle("Sign Up", forState: UIControlState.Normal)
            
            //change the toggle sign up button's title and state back to Log in
            toggleSignUpButton.setTitle("Switch to Login", forState: UIControlState.Normal)
            
            //change the signupState back to true
            signupState = true
            
            //unhide the labels by adjusting its alpha back to 1
            riderLabel.alpha = 1
            driverLabel.alpha = 1
            `switch`.alpha = 1
            
            
        }
        
    }
    
    //expects a title and a message argument of type String
    func displayAlert(title: String, message: String) {
        //expects the if available
        if #available(iOS 8.0, *) {
            var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)

        } else {
            // Fallback on earlier versions
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //typ UITapGestureRecognizer, that targets itself (view controller) using the action (function) Dismiss Keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        //add the gesture recognizer to the view
        view.addGestureRecognizer(tap)
        //apply to the specific text field(s)
        self.username.delegate = self
        self.password.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func DismissKeyboard() {
        //causes the view to resign the first responder status when tapping outside of the keyboard
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        //this is similar to the dismiss keyboard except for the return key
        self.view.endEditing(true)
        return false
    }
    
    //this method is to ensure that the segue happens before the viewdidLoad runs
    override func viewDidAppear(animated: Bool) {
        //perform a check for the current user. Parse docs say to check for currentuser, however, check for the currentUser's username instead to ensure that it is nil so it doesn't segue to the viewcontroller after logout. Logging out the user still creates a currentuser object, in which case, the segue would fire again
        if PFUser.currentUser()?.username != nil {
            
            //check to see if the cuser is a driver or rider during login. The segue should go to the correct place depending if the cuser is a rider or driver
            if PFUser.currentUser()?["isDriver"]! as! Bool == true {
                //when the the user is successfully logged in, segue to the rider view controller via segue. Later on, check to see if the user is logging in as a rider or a driver. In this case, segue to the driver since the cuser is a driver
                self.performSegueWithIdentifier("loginDriver", sender: self)
                
                
            } else {
                
                //when the the user is successfully logged in, segue to the rider view controller via segue. Later on, check to see if the user is logging in as a rider or a driver
                self.performSegueWithIdentifier("loginRider", sender: self)
                
            }

            
    
        }
    }
}
