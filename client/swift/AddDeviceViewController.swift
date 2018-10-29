//
//  AddDeviceViewController.swift
//  Monitor
//
//  Created by Arjon Das on 10/3/18.
//  Copyright © 2018 Arjon Das. All rights reserved.
//

import UIKit
import Alamofire

class AddDeviceViewController: UIViewController {
    
    @IBOutlet weak var serialNoInput: UITextField!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var responseLabel: UILabel!
    @IBOutlet weak var deviceName: UITextField!
    
    @IBAction func serialSubmit(_ sender: Any) {
        addDeviceHandler()
    }
    
    @IBAction func back(_ sender: Any) {
//        self.dismiss(animated: true, completion: nil)
        (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
    }
    
    var tokenGlobal : String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideKeyboardWhenTappedAround()
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "x-auth") as? String
        
        responseLabel.text = ""
        
        if token == nil {
//            self.dismiss(animated: true, completion: nil)
            (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
        } else {
            tokenGlobal = (token)!
        }
    }
    
    func addDeviceHandler() {
        let url : String = (UIApplication.shared.delegate as! AppDelegate).url + "device"
        let parameters: Parameters = [
            "name": deviceName.text as Any,
            "serial": serialNoInput.text as Any
        ]
        let headers : HTTPHeaders = [
            "x-auth": tokenGlobal
        ]
        loading.isHidden = false
        loading.startAnimating()
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success:
                self.responseLabel.text = "Device Added Successfully"
                self.responseLabel.textColor = UIColor.green
            case .failure:
                self.responseLabel.text = "Failed Adding Device"
                self.responseLabel.textColor = UIColor.red
            }
            self.loading.stopAnimating()
            self.loading.isHidden = true
            self.perform(#selector(self.vanishResponse), with: nil, afterDelay: 3)
        }
    }
    
    @objc func vanishResponse() {
        print("vanishing")
        responseLabel.text = ""
        responseLabel.textColor = UIColor.clear
    }
    
//    func startMenuViewController() {
//        let menuViewController = self.storyboard?.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
//        self.present(menuViewController, animated: true, completion: nil)
//    }
//
//    func startSignInViewController() {
//        print("Token doesn't exist")
//        let signInViewController = self.storyboard?.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
//        self.present(signInViewController, animated: true, completion: nil)
//    }
    
}
