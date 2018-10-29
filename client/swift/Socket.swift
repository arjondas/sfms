//
//  Socket.swift
//  Monitor
//
//  Created by Arjon Das on 10/12/18.
//  Copyright © 2018 Arjon Das. All rights reserved.
//
import UIKit
import SocketIO
import Alamofire

class Socket {
    let manager = SocketManager(socketURL: URL(string: Bundle.main.object(forInfoDictionaryKey: "Server IP") as! String)!, config: [.log(false), .compress])
    var socket : SocketIOClient
    init () {
        socket = manager.defaultSocket
    }
    
    func Connect() {
        socket.on(clientEvent: .connect) { data, ack in
            self.socket.emitWithAck("join", Bundle.main.object(forInfoDictionaryKey: "Serial") as! String).timingOut(after: 1) { data in
                print(data[0])
            }
        }
        socket.connect()
    }
    
    func ListenToControlTempSwitch(toggle : UISwitch) {
        socket.on("temp_control_monitor") { (data, ack) in
            let controls = data[0] as! Dictionary <String, Any>
            if controls["set"] as! String == "temperature" {
                toggle.setOn(controls["monitoring"] as! Bool, animated: true)
            }
        }
    }
    
    func ListenToControlTempLimit(textField : UITextField) {
        socket.on("temp_control_threshold") { (data, ack) in
            let controls = data[0] as! Dictionary <String, Any>
            if controls["set"] as! String == "temperature" {
                textField.text = String(controls["threshold"] as! Float)
            }
        }
    }
    
    func ListenToControlInventrySwitch(toggle : UISwitch) {
        socket.on("inventry_control_monitor") { (data, ack) in
            let controls = data[0] as! Dictionary <String, Any>
            if controls["set"] as! String == "weight" {
                toggle.setOn(controls["monitoring"] as! Bool, animated: true)
            }
        }
    }
    
    func ListenToControlInventryLimit(textField : UITextField) {
        socket.on("inventry_control_threshold") { (data, ack) in
            let controls = data[0] as! Dictionary <String, Any>
            if controls["set"] as! String == "weight" {
                textField.text = String(controls["threshold"] as! Float)
            }
        }
    }
    
    func EmitTempToggle(deviceID: String, value: Bool) {
        let payload : Dictionary <String, Any> = [
            "set": "temperature",
            "monitoring": value
        ]
        socket.emit("temp_control_monitor", payload, deviceID)
    }
    
    func EmitTempLimit(deviceID: String, value: Float) {
        let payload : Dictionary <String, Any> = [
            "set": "temperature",
            "threshold": value
        ]
        socket.emit("temp_control_threshold", payload, deviceID)
    }
    
    func EmitInventryToggle(deviceID: String, value: Bool) {
        let payload : Dictionary <String, Any> = [
            "set": "weight",
            "monitoring": value
        ]
        socket.emit("inventry_control_monitor", payload, deviceID)
    }
    
    func EmitInventryLimit(deviceID: String, value: Float) {
        let payload : Dictionary <String, Any> = [
            "set": "weight",
            "threshold": value
        ]
        socket.emit("inventry_control_threshold", payload, deviceID)
    }
    
    func pinging() {
        getDeviceWarningData(completion: {(temp, weight) in
            if temp != "" {
                print("triggering temp notification")
                self.triggerNotification(msg: ("Temperature Alert", temp))
            }
            if weight != "" {
                print("triggering weight notification")
                self.triggerNotification(msg: ("Inventory Alert", weight))
            }
        })
    }
    
    func triggerNotification(msg : (String, String)) {
        let localNotification = UILocalNotification()
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 2) as Date
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.userInfo = [
            "message": "Test notification msg"
        ]
        localNotification.alertBody = "\(msg.0)! Devices: \(msg.1)"
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
    
    func resetNotification(for entryID : String, type : String, headers: HTTPHeaders) {
        let url : String = Bundle.main.object(forInfoDictionaryKey: "Server IP") as! String + "notification/" + type + "/" + entryID + "/"
        print(url)
        Alamofire.request(url, method: .get, headers: headers).validate().responseString { response in
            switch response.result {
            case .success:
                print("Alert Reset Successful")
            case .failure(let err):
                print("Alert Reset Not Successful, might alert again")
                print(err)
            }
        }
    }
    
    func getDeviceWarningData(completion:@escaping ((String,String)) -> Void) {
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "x-auth") as? String
        if token == nil {
            return
        }
        let headers : HTTPHeaders = [
            "x-auth": token!
        ]
        let url : String = Bundle.main.object(forInfoDictionaryKey: "Server IP") as! String + "device/"
        var targetDevicesTemp : String = ""
        var targetDevicesWeight : String = ""
        Alamofire.request(url, method: .get, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success:
                if let responseObject = response.result.value {
                    let deviceList : [Dictionary] = responseObject as! [Dictionary<String, Any>]
                    for device in deviceList {
                        let name = device["_name"] as! String
                        let entryID = device["_id"] as! String
                        let warnTemp = device["warnTemp"] as! Bool
                        let warnWeight = device["warnWeight"] as! Bool
                        if warnTemp {
                            if targetDevicesTemp == "" {
                                targetDevicesTemp = targetDevicesTemp + name
                            } else {
                                targetDevicesTemp = targetDevicesTemp + ", \(name)"
                            }
                            self.resetNotification(for: entryID, type: "temperature", headers: headers)
                        }
                        if warnWeight {
                            if targetDevicesWeight == "" {
                                targetDevicesWeight = targetDevicesWeight + name
                            } else {
                                targetDevicesWeight = targetDevicesWeight + ", \(name)"
                            }
                            self.resetNotification(for: entryID, type: "weight", headers: headers)
                        }
                    }
                }
                completion((targetDevicesTemp, targetDevicesWeight))
                break
            case .failure:
                targetDevicesTemp = ""
                targetDevicesWeight = ""
                completion((targetDevicesTemp, targetDevicesWeight))
                break
            }
        }
    }
    
    func fetchImage(imageView: UIImageView, loading: UIActivityIndicatorView) {
        loading.startAnimating()
        socket.emit("imageFetch", true)
        socket.on("clientImageFetch") { (data, ack) in
            self.socket.off("clientImageFetch")
            let rawData = data[0] as! String
            let imageData = NSData(base64Encoded: rawData, options: .ignoreUnknownCharacters)
            let image = UIImage(data: imageData! as Data)
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            imageView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
            imageView.isHidden = false
            loading.stopAnimating()
        }
        let dispatch : DispatchQueue = DispatchQueue.main
        dispatch.asyncAfter(deadline: .now() + .seconds(10), execute: {
            loading.stopAnimating()
            self.socket.off("clientImageFetch")
        })
    }
}
