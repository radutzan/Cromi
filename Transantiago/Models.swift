//
//  Models.swift
//  Transantiago
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import MapKit

class TransantiagoAnnotation: NSObject, MKAnnotation {
    
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let commune: String
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, commune: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.commune = commune
    }
    
}

class StopAnnotation: TransantiagoAnnotation, CreatableFromJSON {
    
    let code: String
    let number: Int?
    let services: [Service]
    
    init(code: String, number: Int?, services: [Service], coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, commune: String) {
        self.code = code
        self.number = number
        self.services = services
        super.init(coordinate: coordinate, title: title, subtitle: subtitle, commune: commune)
    }
    
    convenience required init?(json: [String: Any]) {
        guard let type = json["type"] as? Int, type == 0 else { return nil }
        guard let commune = json["comuna"] as? String else { return nil }
        guard let name = json["name"] as? String else { return nil }
        guard let location = (json["pos"] as? [NSNumber]).map({ $0.toDoubleArray() }) else { return nil }
        guard let code = json["cod"] as? String else { return nil }
        let stopNumber = json["num"] as? Int
        let services: [Service] = []//Servicios.createRequiredInstances(from: json, arrayKey: "servicios")
        self.init(code: code, number: stopNumber, services: services, coordinate: CLLocationCoordinate2D(latitude: location[0], longitude: location[1]), title: name, subtitle: nil, commune: commune)
    }
    
}

struct Service {
    
}

struct StopPrediction {
    
}
