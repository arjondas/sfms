//
//  PlotViewController.swift
//  Monitor
//
//  Created by Arjon Das on 10/18/18.
//  Copyright © 2018 Arjon Das. All rights reserved.
//

import UIKit
import Alamofire
import Charts

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

extension Numeric {
    
    private func _precision(number: NSNumber, precision: Int, roundingMode: NumberFormatter.RoundingMode) -> Self? {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        formatter.roundingMode = roundingMode
        if let formatedNumString = formatter.string(from: number), let formatedNum = formatter.number(from: formatedNumString) {
            return formatedNum as? Self
        }
        return nil
        
    }
    
    func precision(_ number: Int, roundingMode: NumberFormatter.RoundingMode = NumberFormatter.RoundingMode.halfUp) -> Self? {
        
        if let num = self as? NSNumber {
            return _precision(number: num, precision: number, roundingMode: roundingMode)
        }
        if let string = self as? String, let double = Double(string) {
            return _precision(number: NSNumber(value: double), precision: number, roundingMode: roundingMode)
        }
        return nil
    }
}


class PlotViewController: UIViewController {
    
    var tokenGlobal : String = ""
    var deviceID : String = ""
    var deviceName : String = ""
    var tempData : [Dictionary<String, Any>]!
    var formattedData : [[Double: Int]] = []
    var graph : UIView!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var chartLabel: UILabel!
    @IBAction func back(_ sender: Any) {
        (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
        formattedData.removeAll()
        tempData.removeAll()
        graph.removeFromSuperview()
        graph = nil
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        graph = UIView()
//        formattedData = []
//        tempData = []
        chartLabel.text = "Chart"
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "x-auth") as? String
        if token == nil {
            (UIApplication.shared.delegate as! AppDelegate).dismiss(viewController: self)
        } else {
            tokenGlobal = (token)!
        }

        loadData {
            self.formatData()
            self.plotData()
        }
    }
    
    
    func plotData() {
        let x: CGFloat = 10
        let y: CGFloat = 50
        let width = self.view.frame.width
        let height = self.view.frame.height
        if formattedData.count > 0 {
            graph = nil
            let datePoint = formattedData.last
            let date = Date(timeIntervalSince1970: (datePoint?.keys.first)!)
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(abbreviation: "BDT")
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "MMM YYYY"
            let strDate = dateFormatter.string(from: date)
            chartLabel.text = strDate
            graph = GraphView(frame: CGRect(x: x, y: y, width: width-x*2, height: height * 0.5), data: formattedData)
//            graph = GraphView(frame: CGRect(x: x, y: y, width: width-x*2, height: height * 0.5), data: myData)
            self.view.addSubview(graph)
        } else {
            chartLabel.text = "No Data"
        }
    }
    
    func loadData(completion: @escaping (() -> Void)) {
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
                    let logs : Dictionary = device["logs"] as! Dictionary<String,Any>
                    let tempData : [Dictionary] = logs["tempData"] as! [Dictionary<String,Any>]
                    self.tempData = tempData
                    completion()
                }
            case .failure:
                print("Error")
            }
        }
    }
    
    func formatData() {
        var fullData : [Dictionary<Double, Int>] = []
        var i = 0;
        for data in tempData {
            let time = data["time"] as! Double
            let temp = Int((data["data"] as! CGFloat).precision(1)! * 10)
            let unitData : Dictionary<Double, Int> = [time : temp]
            fullData.append(unitData)
        }
        let dataPoints : Int = 10
        let totalPoints : Int = fullData.count
        let pointInterval : Int = 100            /// Setting 10 means data interval of 1 min as 6 sec between each data
        i = totalPoints - dataPoints * pointInterval
        i = i < 0 ? 0 : i
        while i < totalPoints {
            let temp : Dictionary<Double, Int> = fullData[i]
            formattedData.append(temp)
            i = i + pointInterval
            if i >= totalPoints {
                formattedData.append(fullData.last!)
                break
            }
        }
    }
}
