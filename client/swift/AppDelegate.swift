//
//  AppDelegate.swift
//  Monitor
//
//  Created by Arjon Das on 9/29/18.
//  Copyright © 2018 Arjon Das. All rights reserved.
//

import UIKit
import CoreData

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let serial = "1"
    let url = Bundle.main.infoDictionary!["Server IP"] as! String
    let socket = Socket()
    var timer = 0
    
    let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
    
    var dispatch : DispatchQueue = DispatchQueue.main
    var isActive : Bool = true
    
    var viewControllers : [UIViewController]!
    
    var menuViewController : MenuViewController!
    var signInViewController : SignInViewController!
    var deviceViewController : DeviceViewContoller!
    var panelViewController : PanelViewController!
    var addDeviceViewController : AddDeviceViewController!
    var plotViewController : PlotViewController!
    
    func startAltMenuViewController() {
//        print("********Showing Alternate Menu View Controller")
        viewControllers.append(menuViewController)
        self.window?.rootViewController?.present(menuViewController, animated: true, completion: nil)
    }
    
    func startAltSignInViewController() {
//        print("Token doesn't exist")
        viewControllers.append(signInViewController)
        self.window?.rootViewController?.present(signInViewController, animated: true, completion: nil)
    }
    
    func startAltDeviceViewController() {
//        print("********Launching Alternate Device List")
        viewControllers.append(deviceViewController)
        self.window?.rootViewController?.presentedViewController?.present(deviceViewController, animated: true, completion: nil)
    }
    
    func startAltPanelViewController(name: String, id: String) {
//        print("*********Showing Alternate Details View Controller")
        panelViewController.deviceID = id
        panelViewController.deviceName = name
        viewControllers.append(panelViewController)
        deviceViewController.present(panelViewController, animated: true, completion: nil)
    }
    
    func startAltAddDeviceViewController() {
//        print("Launching Add Device")
        viewControllers.append(addDeviceViewController)
        self.window?.rootViewController?.presentedViewController?.present(addDeviceViewController, animated: true, completion: nil)
    }
    
    func startAltPlotViewController(name: String, id: String) {
        plotViewController.deviceID = id
        plotViewController.deviceName = name
        viewControllers.append(plotViewController)
        panelViewController.present(plotViewController, animated: true, completion: nil)
    }
    
    func dismiss(viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
        viewControllers.removeLast()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        viewControllers = [UIViewController]()
        menuViewController = mainStoryBoard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        signInViewController = mainStoryBoard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
        deviceViewController = mainStoryBoard.instantiateViewController(withIdentifier: "DeviceViewController") as! DeviceViewContoller
        panelViewController = mainStoryBoard.instantiateViewController(withIdentifier: "PanelViewController") as! PanelViewController
        addDeviceViewController = mainStoryBoard.instantiateViewController(withIdentifier: "AddDeviceViewController") as! AddDeviceViewController
        plotViewController = mainStoryBoard.instantiateViewController(withIdentifier: "PlotViewController") as! PlotViewController
        
        let notificationSettings = UIUserNotificationSettings(types: [.alert, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        return true
    }

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        self.takeActionWithNotification(notification: notification)
    }
    
    func takeActionWithNotification(notification: UILocalNotification) {
//        let lastViewController = viewControllers.last
//        var message = ""
//        if (lastViewController?.isKind(of: UIAlertController.self))! {
//            message = (lastViewController as! UIAlertController).message! + "\n" + notification.alertBody!
//            dismiss(viewController: lastViewController!)
//        } else {
//            message = notification.alertBody!
//        }
//        let alertController = UIAlertController(title: "Alert!!", message: message, preferredStyle: .alert)
//        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
//        alertController.addAction(dismissAction)
//        viewControllers.last?.present(alertController, animated: true, completion: nil)
////        self.window?.rootViewController?.presentedViewController?.present(alertController, animated: true, completion: nil)
        let alertViewController = UIAlertController(title: "Alert!!!", message: notification.alertBody, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alertViewController.addAction(dismissAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindowLevelAlert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alertViewController, animated: true, completion: nil)
    }
    
    func triggerNotification(msg : (String, String)) {
        let localNotification = UILocalNotification()
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
        localNotification.applicationIconBadgeNumber = 1
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.userInfo = [
            "message": "Device Alert!!"
        ]
        localNotification.alertBody = "\(msg.0)! Devices: \(msg.1)"
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        isActive = false
        application.beginBackgroundTask(withName: "pinging", expirationHandler: nil)
        performSelector(inBackground: #selector(pinging), with: nil)
    }
    
    @objc func pinging() {
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "x-auth") as? String
        if token != nil {
            print("background pinging")
            socket.pinging()
        }
        if !isActive {
            sleep(6)
            performSelector(inBackground: #selector(pinging), with: nil)
        } else {
            return
        }
    }
    
    @objc func checking() {
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "x-auth") as? String
        if token != nil {
            print("foreground pinging")
            socket.pinging()
        }
        if isActive {
            dispatch.asyncAfter(deadline: .now() + .seconds(6), execute: {
                self.perform(#selector(self.checking))
            })
        } else {
            return
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        isActive = true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        perform(#selector(checking))
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Monitor")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if #available(iOS 10.0, *) {
            let context = persistentContainer.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
    }

}

//    func startMenuViewController() {
//        print("Showing Menu View Controller")
//        let menuViewController = self.storyboard?.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
//        self.view.window?.rootViewController = menuViewController
//        self.present(menuViewController, animated: true, completion: nil)
//    }
//
//    //***************
//    func startDeviceViewController() {
//        print("Launching Device List")
//        let deviceViewController = self.storyboard?.instantiateViewController(withIdentifier: "DeviceViewController") as! DeviceViewContoller
//        self.present(deviceViewController, animated: true, completion: nil)
//    }
//    //***************
//    func startSignInViewController() {
//        print("Token doesn't exist")
//        let signInViewController = self.storyboard?.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
//        self.present(signInViewController, animated: true, completion: nil)
//    }
//
//    func startAddDeviceViewController() {
//        print("Launching Add Device")
//        let addDeviceViewController = self.storyboard?.instantiateViewController(withIdentifier: "AddDeviceViewController") as! AddDeviceViewController
//        self.present(addDeviceViewController, animated: true, completion: nil)
//    }
//
//    func startDetailsViewController(name: String, id: String) {
//        print("Showing Details")
//        let detailsViewController = self.storyboard?.instantiateViewController(withIdentifier: "PanelViewController") as! PanelViewController
//        detailsViewController.deviceID = id
//        detailsViewController.deviceName = name
//        self.present(detailsViewController, animated: true, completion: nil)
//    }


