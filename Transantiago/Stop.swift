//
//  Stop.swift
//  Cromi
//
//  Created by Radu Dutzan on 10/2/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import MapKit

// MARK: - Stop
class Stop: TransantiagoAnnotation, NSCoding {
    let code: String
    let number: Int?
    let services: [Service]
    var selectedServices: [Service] = []
    var favoriteName: String?
    
    init(code: String, number: Int?, services: [Service], coordinate: CLLocationCoordinate2D, title: String, subtitle: String?, commune: String) {
        self.code = code
        self.number = number
        self.services = services
        super.init(coordinate: coordinate, title: title, subtitle: subtitle, commune: commune)
    }
    
    required init?(coder decoder: NSCoder) {
        guard let code = decoder.decodeObject(forKey: "code") as? String,
            let services = decoder.decodeObject(forKey: "services") as? [Service] else { return nil }
        self.code = code
        let number = decoder.decodeInteger(forKey: "number")
        self.number = number == 0 ? nil : number
        self.services = services
        self.selectedServices = decoder.decodeObject(forKey: "selectedServices") as? [Service] ?? []
        self.favoriteName = decoder.decodeObject(forKey: "favoriteName") as? String
        super.init(coder: decoder)
    }
    
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(code, forKey: "code")
        coder.encode(number, forKey: "number")
        coder.encode(services, forKey: "services")
        coder.encode(selectedServices, forKey: "selectedServices")
        coder.encode(favoriteName, forKey: "favoriteName")
    }
    
    override var hashValue: Int {
        return code.hashValue ^ 420.hashValue
    }
    
    static func ==(rhs: Stop, lhs: Stop) -> Bool {
        return rhs.code == lhs.code
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherStop = object as? Stop else { return false }
        return self == otherStop
    }
}

// MARK: - Stop prediction
struct StopPrediction {
    let timestamp: Date
    let stopCode: String
    let responseString: String?
    let serviceResponses: [ServiceResponse]
    
    struct ServiceResponse {
        enum Kind: Int {
            case twoPredictions = 00, onePrediction = 01, noPrediction = 9, noIncomingBuses = 10, outOfSchedule = 11
        }
        
        let kind: Kind
        let serviceName: String
        let predictions: [Prediction]?
        
        struct Prediction {
            let distance: Int
            let predictionString: String
            let licensePlate: String?
        }
    }
}
