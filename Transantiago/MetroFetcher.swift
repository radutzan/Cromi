//
//  MetroFetcher.swift
//  Cromi
//
//  Created by Radu Dutzan on 3/20/20.
//  Copyright © 2020 Radu Dutzan. All rights reserved.
//

import UIKit

class MetroFetcher: NSObject {
    static let shared = MetroFetcher()
    
    func refreshMetroIfNeeded() {
        guard Date().timeIntervalSince(Storage.shared.metroLinesUpdateDate) > (30*24*60*60) else {
            dlog("No update needed")
            return
        }
        fetchMetroLines()
    }
    
    private func fetchMetroLines() {
        dlog("Fetching lines")
        var expectedLineCount = 0
        var lines: [MetroLine] = [] {
            didSet {
                if lines.count == expectedLineCount {
                    Storage.shared.metroLines = lines
                }
            }
        }
        
        SCLTransit.get.services(for: "M") { (services) in
            expectedLineCount = services.count
            for service in services {
                guard !service.name.hasSuffix("R"), !service.name.hasSuffix("V") else {
                    expectedLineCount -= 1
                    continue
                }
                SCLTransit.get.serviceRoutes(for: service) { (service) in
                    guard let service = service else {
                        expectedLineCount -= 1
                        return
                    }
                    lines.append(MetroLine(name: service.name, color: service.color, routes: service.routes))
                }
            }
        }
    }

}
