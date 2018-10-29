//
//  ViewController.swift
//  Monitor
//
//  Created by Arjon Das on 9/29/18.
//  Copyright © 2018 Arjon Das. All rights reserved.
//

import UIKit
import Alamofire

class MainViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "x-auth") as? String
        self.dismiss(animated: true, completion: nil)
        if token == nil {
//            startSignInViewController()
            (UIApplication.shared.delegate as! AppDelegate).startAltSignInViewController()
        } else {
            print("already signed in")
//            startMenuViewController()
            (UIApplication.shared.delegate as! AppDelegate).startAltMenuViewController()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

