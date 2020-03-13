//
//  Models.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import MapKit

// MARK: - Operation hours
struct OperationHours: Encodable {
    let rangeTitle: String
    let start: String
    let end: String
}

// MARK: - Service
class Service: NSObject, NSCoding {
    
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
        
        var encodableDictionary: [String: Any] {
            let dictionary: [String: Any] = [
                "direction": direction.rawValue,
                "operationHours": operationHours.map { $0.dictionary },
                "headsign": headsign,
                "polyline": polyline.coordinates.map { Coordinate(clLocationCoordinate2D: $0) },
                "stops": stops ?? [],
                "stopCodes": stopCodes]
            return dictionary
        }
        
        static func decode(from dictionary: [String: Any]) -> Route? {
            guard let rawDirection = dictionary["direction"] as? Int,
                let direction = Direction(rawValue: rawDirection),
                let operationHoursData = dictionary["operationHours"] as? [[String: Any]],
                let headsign = dictionary["headsign"] as? String,
                let polylineData = dictionary["polyline"] as? [Coordinate],
                let stopCodes = dictionary["stopCodes"] as? [String] else { return nil }
            var operationHours: [OperationHours] = []
            for opHourData in operationHoursData {
                guard let rangeTitle = opHourData["rangeTitle"] as? String, let start = opHourData["start"] as? String, let end = opHourData["end"] as? String else { continue }
                operationHours.append(OperationHours(rangeTitle: rangeTitle, start: start, end: end))
            }
            let coordinates = polylineData.map { $0.clRepresentation }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            return Route(direction: direction, operationHours: operationHours, headsign: headsign, polyline: polyline, stops: dictionary["stops"] as? [Stop], stopCodes: stopCodes)
        }
    }
    
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
    
    struct StopInfo: Equatable {
        let headsign: String
        let direction: Route.Direction
        
        static func ==(lhs: StopInfo, rhs: StopInfo) -> Bool {
            return lhs.headsign == rhs.headsign && lhs.direction == rhs.direction
        }
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
    
    required init?(coder: NSCoder) {
        guard let name = coder.decodeObject(forKey: "name") as? String, let color = coder.decodeObject(forKey: "color") as? UIColor else { return nil }
        self.name = name
        self.color = color
        let routes = coder.decodeObject(forKey: "routes") as? [[String: Any]]
        self.routes = routes?.map { Route.decode(from: $0) }.compactMap { $0 }
        self.destinationString = coder.decodeObject(forKey: "destinationString") as? String
        self.stopInfo = nil
        super.init()
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(color, forKey: "color")
        coder.encode(routes?.map { $0.encodableDictionary }, forKey: "routes")
        coder.encode(destinationString, forKey: "destinationString")
    }
    
    static func ==(lhs: Service, rhs: Service) -> Bool {
        return lhs.name == rhs.name && lhs.stopInfo == rhs.stopInfo
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherService = object as? Service else { return false }
        return self == otherService
    }
}

class MetroLine: Service {}
