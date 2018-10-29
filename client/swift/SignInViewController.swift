//
//  SignInViewController.swift
//  Monitor
//
//  Created by Arjon Das on 9/30/18.
//  Copyright © 2018 Arjon Das. All rights reserved.
//

import UIKit
import Alamofire

class SignInViewController: UIViewController, UITextFieldDelegate {
    
    var isSignIN: Bool = true
    var _urlBase: String = ""
    var _urlSignIn: String = "user/login"
    var _urlSignUp: String = "user/new"
    
    @IBOutlet weak var actionLabel: UILabel!
    
    @IBOutlet weak var responseLabel: UILabel!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBAction func submitButton(_ sender: Any) {
        signInHandler()
    }
    
    @IBAction func alternateButton(_ sender: Any) {
        isSignIN = !isSignIN
        let button = (sender as AnyObject)
        
        if isSignIN {
            button.setTitle("Don't have an account?", for: .normal)
            actionLabel.text = "Sign In"
        } else {
            button.setTitle("Have an account?", for: .normal)
            actionLabel.text = "Sign Up"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideKeyboardWhenTappedAround()
        print("hello")
        emailField.delegate = self
        passwordField.delegate = self
        _urlBase = (UIApplication.shared.delegate as! AppDelegate).url
        
        isSignIN = true
        responseLabel.text = ""
        emailField.text = ""
        passwordField.text = ""
        emailField.placeholder = "Email"
        passwordField.placeholder = "Password"
        
        if isSignIN {
            actionLabel.text = "Sign In"
        } else {
            actionLabel.text = "Sign Up"
        }
    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func signInHandler() {
        let parameters: Parameters = [
            "email": emailField.text as Any,
            "password": passwordField.text as Any
        ]
        
        let url : String = isSignIN ? _urlBase + _urlSignIn : _urlBase + _urlSignUp
        print(url)
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { response in
            switch response.result {
            case .success:
                if self.isSignIN {
                    self.responseLabel.text = "Successfully Signed In"
                } else {
                    self.responseLabel.text = "Successfully Signed Up"
                }
                if let token = response.response?.allHeaderFields["x-auth"] {
                    var email : String
                    if let responseObject = response.result.value {
                        let accountInfo : Dictionary = responseObject as! Dictionary<String, Any>
                        email = accountInfo["email"] as! String
                    } else {
                        email = ""
                    }
                    let defaults = UserDefaults.standard
                    defaults.set(token as! String, forKey: "x-auth")
                    defaults.set(email, forKey: "email")
                }
                self.responseLabel.textColor = UIColor.green
            
//                self.dismiss(animated: true, completion: nil)
                (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
                
            case .failure:
                if self.isSignIN {
                    self.responseLabel.text = "Sign In Failed"
                } else {
                    self.responseLabel.text = "Sign Up Failed"
                    print("failed")
                }
                self.responseLabel.textColor = UIColor.red
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}

