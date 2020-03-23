//
//  Storage.swift
//  Cromi
//
//  Created by Radu Dutzan on 3/11/20.
//  Copyright © 2020 Radu Dutzan. All rights reserved.
//

import RaduKit

class Storage: Chest {
    static var fileName: String {
        return "Cromi Storage"
    }
    
    var metroLines: [MetroLine] = [] {
        didSet {
            metroLinesUpdateDate = Date()
            didUpdateData()
        }
    }
    private(set) var metroLinesUpdateDate = Date.distantPast
    
    // MARK: - Read/write
    override init() {
        super.init()
    }
    
    required init?(coder decoder: NSCoder) {
        self.metroLines = decoder.decodeObject(forKey: "metroLines") as? [MetroLine] ?? []
        self.metroLinesUpdateDate = decoder.decodeObject(forKey: "metroLinesUpdateDate") as? Date ?? Date.distantPast
        super.init(coder: decoder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(metroLines, forKey: "metroLines")
        coder.encode(metroLinesUpdateDate, forKey: "metroLinesUpdateDate")
    }
}
