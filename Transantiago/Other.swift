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

// MARK: - Coordinate
class Coordinate: NSObject, NSCoding {
    var latitude: Double = 0
    var longitude: Double = 0
    var clRepresentation: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(clLocationCoordinate2D coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        super.init()
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        super.init()
    }
    
    required init?(coder decoder: NSCoder) {
        self.latitude = decoder.decodeDouble(forKey: "latitude")
        self.longitude = decoder.decodeDouble(forKey: "longitude")
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(latitude, forKey: "latitude")
        coder.encode(longitude, forKey: "longitude")
    }
}

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
        let results = routes?.filter { $0.direction == .outbound } ?? []
        return results.count > 0 ? results[0] : nil
    }
    var inboundRoute: Route? {
        let results = routes?.filter { $0.direction == .inbound } ?? []
        return results.count > 0 ? results[0] : nil
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
        let stops: [Stop]?
        let stopCodes: [String]
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
        return lhs.name == rhs.name
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherService = object as? Service else { return false }
        return self == otherService
    }
}

class MetroLine: Service {}
