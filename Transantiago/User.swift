//
//  User.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/1/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import RaduKit

class User: Chest {
    static var fileName: String {
        return "Cromi User Data"
    }
    
    var bipCards: [BipCard] = [] {
        didSet {
            didUpdateData()
        }
    }
    var favoriteStops: [Stop] = [] {
        didSet {
            didUpdateData()
        }
    }
    
    // MARK: - Read/write
    override init() {
        super.init()
    }
    
    required init?(coder decoder: NSCoder) {
        self.bipCards = decoder.decodeObject(forKey: "bipCards") as? [BipCard] ?? []
        self.favoriteStops = decoder.decodeObject(forKey: "favoriteStops") as? [Stop] ?? []
        super.init(coder: decoder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(bipCards, forKey: "bipCards")
        coder.encode(favoriteStops, forKey: "favoriteStops")
    }
}
