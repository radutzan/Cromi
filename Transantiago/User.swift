//
//  User.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/1/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class User: NSObject, NSCoding {
    // MARK: - Definitions
    static var filePath: String {
        let basePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Cromi User Data", isDirectory: false)
        return basePath.path
    }
    
    struct Notifications {
        static let dataUpdated = Notification.Name("User data has been updated.")
        struct Internal {
            fileprivate static let updateActionsRequested = Notification.Name("User data update actions requested.")
            fileprivate static let saveRequested = Notification.Name("User data save requested.")
        }
    }
    
    // MARK: - Data
    var bipCards: [BipCard] = [] {
        didSet {
            didUpdateData()
        }
    }
    
    // MARK: - Initializing
    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder decoder: NSCoder) {
        self.bipCards = decoder.decodeObject(forKey: "bipCards") as? [BipCard] ?? []
        super.init()
        commonInit()
    }
    
    private func commonInit() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(performUpdateActions),
                                               name: Notifications.Internal.updateActionsRequested,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(saveUserDataIfNeeded),
                                               name: Notifications.Internal.saveRequested,
                                               object: nil)
    }
    
    // MARK: - Saving
    func encode(with coder: NSCoder) {
        coder.encode(bipCards, forKey: "bipCards")
    }
    
    private var needsSave = false
    
    private func setNeedsSave() {
        guard !needsSave else { return }
        needsSave = true
        delay(3) {
            let saveNotification = Notification(name: Notifications.Internal.saveRequested)
            NotificationQueue.default.enqueue(saveNotification, postingStyle: .whenIdle, coalesceMask: .onName, forModes: nil)
        }
        print("User: Save needed set")
    }
    
    @objc private func saveUserDataIfNeeded() {
        guard needsSave else { return }
        needsSave = false
        background {
            print("User: Archiving root object")
            let didSave = NSKeyedArchiver.archiveRootObject(self, toFile: User.filePath)
            if !didSave { print("User: Failed to archive root object") }
        }
    }
    
    // MARK: - Updating
    func didUpdateData() {
        print("User: Data reported as updated")
        mainThread {
            let notification = Notification(name: Notifications.Internal.updateActionsRequested)
            NotificationQueue.default.enqueue(notification, postingStyle: .asap, coalesceMask: .onName, forModes: nil)
        }
    }
    
    @objc private func performUpdateActions() {
        print("User: Performing update actions")
        setNeedsSave()
        notifyDataUpdate()
    }
    
    private func notifyDataUpdate() {
        print("User: Notifying data update")
        mainThread {
            let notification = Notification(name: Notifications.dataUpdated)
            NotificationQueue.default.enqueue(notification, postingStyle: .asap, coalesceMask: .onName, forModes: nil)
        }
    }

}
