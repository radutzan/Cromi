//
//  User.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/1/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import RaduKit

class User: NSObject, Storable {
    struct Notifications {
        static let dataUpdated = Notification.Name("User data has been updated.")
        struct Internal {
            fileprivate static let updateActionsRequested = Notification.Name("User data update actions requested.")
        }
    }
    
    static var fileName: String {
        return "Cromi User Data"
    }
    
    // MARK: - Data
    var bipCards: [BipCard] = [] {
        didSet {
            didUpdateData()
        }
    }
    private var storageManager: StorageManager!
    
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
        storageManager = StorageManager(storable: self)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(performUpdateActions),
                                               name: Notifications.Internal.updateActionsRequested,
                                               object: nil)
    }
    
    // MARK: - Saving
    func encode(with coder: NSCoder) {
        coder.encode(bipCards, forKey: "bipCards")
    }
    
    private func setNeedsSave() {
        storageManager.setNeedsSave()
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
