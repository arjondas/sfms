//
//  DeviceViewController.swift
//  Monitor
//
//  Created by Arjon Das on 10/3/18.
//  Copyright © 2018 Arjon Das. All rights reserved.
//

import UIKit
import Alamofire

class DeviceViewContoller: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var loadingDevice: UIActivityIndicatorView!
    
    @IBOutlet weak var deviceLabel: UILabel!
    
    @IBOutlet weak var deviceTableView: UITableView!
    
    @IBAction func back(_ sender: Any) {
//        self.dismiss(animated: true, completion: nil)
        (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
    }

    var listName: [String] = []
    var listID: [String] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "deviceCell")
        cell.textLabel?.text = listName[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (UIApplication.shared.delegate as! AppDelegate).startAltPanelViewController(name: listName[indexPath.row], id: listID[indexPath.row])
    }
    
    var tokenGlobal : String = ""
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("********viewDidAppear_DeviceViewController***********")
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "x-auth") as? String
        
        if token == nil {
//            self.dismiss(animated: true, completion: nil)
            (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
        } else {
            tokenGlobal = (token)!
        }
        
        requestDevices()
    }
    
    
    func requestDevices() {
        let url : String = (UIApplication.shared.delegate as! AppDelegate).url + "device"
        let headers : HTTPHeaders = [
            "x-auth": tokenGlobal
        ]
        loadingDevice.isHidden = false
        loadingDevice.startAnimating()
        Alamofire.request(url, method: .get, headers: headers).validate().responseJSON { response in
            self.loadingDevice.stopAnimating()
            switch response.result {
            case .success:
                self.listName.removeAll()
                self.listID.removeAll()
                self.deviceLabel.text = "My Devices"
                if let responseObject = response.result.value {
                    let deviceList : [Dictionary] = responseObject as! [Dictionary<String, Any>]
                    for device in deviceList {
                        let name = device["_name"] as! String
                        let id = device["_deviceID"] as! String
                        self.listName.append(name)
                        self.listID.append(id)
                    }
                    self.deviceTableView.reloadData()
                }
            case .failure(let err):
                print(err)
                self.deviceLabel.text = "Error Loading Devices"
            }
        }
        
    }       
}
