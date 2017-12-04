//
//  Models.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import MapKit

// MARK: - Data source
protocol DataSource: AnyObject {
    associatedtype DataSourceType
    static var get: DataSourceType { get }
    
    // MARK: - Requests
    func annotations(aroundCoordinate coordinate: CLLocationCoordinate2D, completion: @escaping ([Stop]?, [BipSpot]?, [MetroStation]?) -> ())
    func prediction(forStopCode code: String, completion: @escaping (StopPrediction?) -> ())
    func service(withName serviceName: String, completion: @escaping (Service?) -> ())
}

// MARK: - Annotations
class TransantiagoAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let commune: String
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String?, commune: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.commune = commune
    }
}

// MARK: - Stop
class Stop: TransantiagoAnnotation {
    let code: String
    let number: Int?
    let services: [Service]
    
    init(code: String, number: Int?, services: [Service], coordinate: CLLocationCoordinate2D, title: String, subtitle: String?, commune: String) {
        self.code = code
        self.number = number
        self.services = services
        super.init(coordinate: coordinate, title: title, subtitle: subtitle, commune: commune)
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

// MARK: - Bip spot
class BipSpot: TransantiagoAnnotation {
    let address: String?
    let operationHours: [OperationHours]
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String?, commune: String, address: String?, operationHours: [OperationHours]) {
        self.address = address
        self.operationHours = operationHours
        super.init(coordinate: coordinate, title: title, subtitle: subtitle, commune: commune)
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

class MetroLine: Service {}

// MARK: - Operation hours
struct OperationHours {
    let rangeTitle: String
    let start: String
    let end: String
}

// MARK: - Service
class Service: NSObject {
    let name: String
    let color: UIColor
    let routes: [Route]?
    var outboundRoute: Route? {
        return routes?.filter { $0.direction == .outbound }[0]
    }
    var inboundRoute: Route? {
        return routes?.filter { $0.direction == .inbound }[0]
    }
    let destinationString: String?
    let stopInfo: StopInfo?
    
    struct StopInfo {
        let headsign: String
        let direction: Route.Direction
    }
    
    struct Route {
        enum Direction: Int {
            case outbound = 0, inbound
        }
        let direction: Direction
        let operationHours: [OperationHours]
        let headsign: String
        let polyline: MKPolyline
        let stops: [Stop]
    }
    
    init(name: String, color: UIColor, routes: [Route]?, destinationString: String?) {
        self.name = name
        self.color = color
        self.routes = routes
        self.destinationString = destinationString
        self.stopInfo = nil
        super.init()
    }
    
    init(name: String, color: UIColor, routes: [Route]?, stopInfo: StopInfo?) {
        self.name = name
        self.color = color
        self.routes = routes
        self.destinationString = stopInfo != nil ? "\(NSLocalizedString("to", comment: "")) \(stopInfo!.headsign)" : nil
        self.stopInfo = stopInfo
        super.init()
    }
    
    static func ==(lhs: Service, rhs: Service) -> Bool {
        return lhs.name == rhs.name && lhs.destinationString == rhs.destinationString
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherService = object as? Service else { return false }
        return self == otherService
    }
}

class Bus: NSObject {
    let plateNumber: String
    let serviceName: String
    var position: CLLocationCoordinate2D
    
    init(plateNumber: String, serviceName: String, position: CLLocationCoordinate2D) {
        self.plateNumber = plateNumber
        self.serviceName = serviceName
        self.position = position
        super.init()
    }
}
