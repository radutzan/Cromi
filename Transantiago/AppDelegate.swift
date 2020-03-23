//
//  AppDelegate.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/7/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit

extension User {
    fileprivate(set) static var current: User!
}

extension Storage {
    fileprivate(set) static var shared: Storage!
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        initSharedObjects()
        return true
    }
    
    private func initSharedObjects() {
        let startTime = CACurrentMediaTime()
        print("AppDelegate: Producing shared objects")
        User.current = NSKeyedUnarchiver.unarchiveObject(withFile: User.filePath) as? User ?? User()
        Storage.shared = NSKeyedUnarchiver.unarchiveObject(withFile: Storage.filePath) as? Storage ?? Storage()
        MetroFetcher.shared.refreshMetroIfNeeded()
        print("AppDelegate: Delivered user at \(CACurrentMediaTime() - startTime) seconds.")
    }
}
