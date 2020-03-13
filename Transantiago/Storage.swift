//
//  Storage.swift
//  Cromi
//
//  Created by Radu Dutzan on 3/11/20.
//  Copyright © 2020 Radu Dutzan. All rights reserved.
//

import RaduKit

class Chest: NSObject, Storable {
    struct Notifications {
        static let dataUpdated = Notification.Name(String(describing: self) + " data has been updated.")
        struct Internal {
            fileprivate static let updateActionsRequested = Notification.Name(String(describing: self) + " data update actions requested.")
        }
    }

    private(set) var storageManager: StorageManager!
    
    // MARK: - Initializing
    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init()
        commonInit()
    }
    
    private func commonInit() {
        storageManager = StorageManager(storable: self)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(performUpdateActions),
                                               name: Notifications.Internal.updateActionsRequested,
                                               object: nil)
    }
    
    // MARK: - Saving
    func encode(with coder: NSCoder) {
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
        storageManager.setNeedsSave()
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


class Storage: Chest {
    static var fileName: String {
        return "Cromi Storage"
    }
    
    // MARK: - Read/write
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override func encode(with coder: NSCoder) {
    }
}
