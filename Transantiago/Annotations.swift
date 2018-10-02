//
//  Annotations.swift
//  Cromi
//
//  Created by Radu Dutzan on 10/2/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import MapKit

class TransantiagoAnnotation: NSObject, MKAnnotation {
    private let underlyingCoordinate: Coordinate
    var coordinate: CLLocationCoordinate2D {
        return underlyingCoordinate.clRepresentation
    }
    let title: String?
    let subtitle: String?
    let commune: String
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String?, commune: String) {
        self.underlyingCoordinate = Coordinate(clLocationCoordinate2D: coordinate)
        self.title = title
        self.subtitle = subtitle
        self.commune = commune
    }
    
    required init?(coder decoder: NSCoder) {
        guard let underlyingCoordinate = decoder.decodeObject(forKey: "underlyingCoordinate") as? Coordinate,
            let commune = decoder.decodeObject(forKey: "commune") as? String else { return nil }
        self.underlyingCoordinate = underlyingCoordinate
        self.title = decoder.decodeObject(forKey: "title") as? String
        self.subtitle = decoder.decodeObject(forKey: "subtitle") as? String
        self.commune = commune
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(underlyingCoordinate, forKey: "underlyingCoordinate")
        coder.encode(title, forKey: "title")
        coder.encode(subtitle, forKey: "subtitle")
        coder.encode(commune, forKey: "commune")
    }
}

// MARK: - Bip spot
class BipSpot: TransantiagoAnnotation {
    let address: String?
    let operationHours: [OperationHours]
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String?, commune: String, address: String?, operationHours: [OperationHours]) {
        self.address = address
        self.operationHours = operationHours
        super.init(coordinate: coordinate, title: title, subtitle: subtitle, commune: commune)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var hashValue: Int {
        return coordinate.latitude.hashValue ^ coordinate.longitude.hashValue ^ (title ?? "").hashValue
    }
    
    static func == (rhs: BipSpot, lhs: BipSpot) -> Bool {
        return rhs.coordinate.latitude == lhs.coordinate.latitude && rhs.coordinate.longitude == lhs.coordinate.longitude && rhs.title == lhs.title
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherSpot = object as? BipSpot else { return false }
        return self == otherSpot
    }
}

// MARK: - Metro station
class MetroStation: BipSpot {
    let lineNumber: Int = 1
    let lineColor: UIColor = .red
    var lines: [MetroLine]?
}

// MARK: - Bus
class Bus: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let plateNumber: String
    let serviceName: String
    
    init(plateNumber: String, serviceName: String, coordinate: CLLocationCoordinate2D) {
        self.plateNumber = plateNumber
        self.serviceName = serviceName
        self.coordinate = coordinate
        super.init()
    }
    
    static func ==(lhs: Bus, rhs: Bus) -> Bool {
        return lhs.plateNumber == rhs.plateNumber && lhs.serviceName == rhs.serviceName && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherBus = object as? Bus else { return false }
        return self == otherBus
    }
}
