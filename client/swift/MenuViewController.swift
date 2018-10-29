//
//  MenuViewController.swift
//  Monitor
//
//  Created by Arjon Das on 10/3/18.
//  Copyright © 2018 Arjon Das. All rights reserved.
//

import UIKit
import Alamofire

class MenuViewController: UIViewController {
    @IBAction func addNew(_ sender: Any) {
        (UIApplication.shared.delegate as! AppDelegate).startAltAddDeviceViewController()
    }
    
    @IBAction func myDevices(_ sender: Any) {
        (UIApplication.shared.delegate as! AppDelegate).startAltDeviceViewController()
    }
    
    @IBAction func signOut(_ sender: Any) {
        signOutHandler()
    }
    
    @IBOutlet weak var email: UILabel!
    
    var tokenGlobal : String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "x-auth") as? String
        
        if token == nil {
//            self.dismiss(animated: true, completion: nil)
            (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
        } else {
            tokenGlobal = (token)!
        }
        email.text = defaults.object(forKey: "email") as? String
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//    }
    
    func signOutHandler() {
        let url : String = (UIApplication.shared.delegate as! AppDelegate).url + "user/logout/"
        let headers : HTTPHeaders = [
            "x-auth": tokenGlobal
        ]
        Alamofire.request(url, method: .delete, headers: headers).validate().responseJSON { response in
            let defaults = UserDefaults.standard
            defaults.set(nil, forKey: "x-auth")
            defaults.set(nil, forKey: "email")
//            self.dismiss(animated: true, completion: nil)
            (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
        }
    }
}
