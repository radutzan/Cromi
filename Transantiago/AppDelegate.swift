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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        initSharedObjects()
        
        BipCard.isCardValid(id: 80718965) { (result, error) in
            print("bip result: \(result ?? false)")
            let card = BipCard(id: 80718965, name: "antipase", color: .yellow)
            delay(3) {
                print(card.id)
                print(card.name)
                print(card.balance)
                print(card.lastUpdated.description(with: Locale.current))
            }
        }
        return true
    }
    
    private func initSharedObjects() {
        let startTime = CACurrentMediaTime()
        print("AppDelegate: Producing shared objects")
        User.current = NSKeyedUnarchiver.unarchiveObject(withFile: User.filePath) as? User ?? User()
        print("AppDelegate: Delivered user at \(CACurrentMediaTime() - startTime) seconds.")
    }

}

