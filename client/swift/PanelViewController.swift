//
//  PanelViewController.swift
//  Monitor
//
//  Created by Arjon Das on 10/3/18.
//  Copyright © 2018 Arjon Das. All rights reserved.
//

import UIKit
import Alamofire
import SocketIO

class PanelViewController: UIViewController, UITextFieldDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let socket = Socket()
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    
    @IBAction func tempLimit(_ sender: Any) {
        let obj = sender as AnyObject
        let inputField = obj as! UITextField
        let input : String? = inputField.text
        if let inputValue = input, !(input?.isEmpty)! {
            let value = Float(inputValue)
            socket.EmitTempLimit(deviceID: deviceID, value: (value)!)
        }
    }
    
    @IBAction func plotTempData(_ sender: Any) {
        (UIApplication.shared.delegate as! AppDelegate).startAltPlotViewController(name: deviceName, id: deviceID)
    }
    
    @IBOutlet weak var foodImage: UIImageView!
    
    @IBOutlet weak var _tempLimit: UITextField!
    
    @IBAction func invLimit(_ sender: Any) {
        let obj = sender as AnyObject
        let inputField = obj as! UITextField
        let input : String? = inputField.text
        if let inputValue = input, !(input?.isEmpty)! {
            let value = Float(inputValue)
            socket.EmitInventryLimit(deviceID: deviceID, value: (value)!)
        }
    }
    
    @IBOutlet weak var _invLimit: UITextField!
    
    @IBAction func tempSwitch(_ sender: Any) {
        let button = sender as AnyObject
        if button.isOn {
            socket.EmitTempToggle(deviceID: deviceID, value: true)
        } else {
            socket.EmitTempToggle(deviceID: deviceID, value: false)
        }
    }
    
    @IBOutlet weak var _tempSwitch: UISwitch!
    
    @IBAction func invSwitch(_ sender: Any) {
        let button = sender as AnyObject
        if button.isOn {
            socket.EmitInventryToggle(deviceID: deviceID, value: true)
        } else {
            socket.EmitInventryToggle(deviceID: deviceID, value: false)
        }
    }
    
    @IBOutlet weak var _invSwitch: UISwitch!
    
    @IBAction func cameraLoad(_ sender: Any) {
        socket.fetchImage(imageView: foodImage, loading: loading)
    }
    
    @IBAction func back(_ sender: Any) {
//        self.dismiss(animated: true, completion: nil)
        print("hello i was dismissed")
        (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
    }
    
    var deviceID = ""
    var deviceName = ""
    var tokenGlobal = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nameLabel.numberOfLines = 2
        foodImage.isHidden = true
        foodImage.isUserInteractionEnabled = true
        loading.hidesWhenStopped = true
        loading.stopAnimating()
        self.hideKeyboardWhenTappedAround()
        _tempLimit.delegate = self
        _invLimit.delegate = self
        nameLabel.text = deviceName
        hideImageWhenTappedAround()
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "x-auth") as? String
        if token == nil {
            (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
        } else {
            tokenGlobal = (token)!
        }
        loadControls()
        socket.Connect()
        socket.ListenToControlTempSwitch(toggle: _tempSwitch)
        socket.ListenToControlTempLimit(textField: _tempLimit)
        socket.ListenToControlInventrySwitch(toggle: _invSwitch)
        socket.ListenToControlInventryLimit(textField: _invLimit)
        //        socket.pinging()
        
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//    }
    
    func hideImageWhenTappedAround() {
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideImage))
        tap.cancelsTouchesInView = false
        foodImage.addGestureRecognizer(tap)
    }
    
    @objc func hideImage() {
        foodImage.isHidden = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func loadControls() {
        let url : String = (UIApplication.shared.delegate as! AppDelegate).url + "device/" + deviceID
        let headers : HTTPHeaders = [
            "x-auth": tokenGlobal
        ]
        Alamofire.request(url, method: .get, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success:
                if let responseObject = response.result.value {
                    let devices : Dictionary = responseObject as! Dictionary<String,Any>
                    let device : Dictionary = devices["device"] as! Dictionary<String,Any>
                    let currentTemp : CGFloat = device["currentTemp"] as! CGFloat
                    let currnetWeight : CGFloat = device["currentWeight"] as! CGFloat
                    let config : Dictionary = device["config"] as! Dictionary<String,Any>
                    let weight : Dictionary = config["weight"] as! Dictionary<String,Any>
                    let temperature : Dictionary = config["temperature"] as! Dictionary<String,Any>
                    let _tempMonitor : Bool = temperature["monitoring"] as! Bool
                    let _tempVal : Float = temperature["threshold"] as! Float
                    let _weightMonitor : Bool = weight["monitoring"] as! Bool
                    let _weightVal : Float = weight["threshold"] as! Float
                    self.nameLabel.text = "Temp: \(currentTemp.precision(1)!) ºC \n Weight: \(currnetWeight.precision(1)!) gm"
                    self._tempLimit.text = String(_tempVal)
                    self._invLimit.text = String(_weightVal)
                    self._tempSwitch.isOn = _tempMonitor
                    self._invSwitch.isOn = _weightMonitor
                }
            case .failure:
                print("Error")
            }
        }
    }
}
