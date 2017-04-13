//
//  Models.swift
//  Transantiago
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import MapKit

// MARK: - Annotations
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

// MARK: - Stop
class Stop: TransantiagoAnnotation, CreatableFromJSON {
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
        guard let type = json["type"] as? Int, type == 0,
            let commune = json["comuna"] as? String,
            let name = json["name"] as? String,
            let location = (json["pos"] as? [NSNumber]).map({ $0.toDoubleArray() }),
            let code = json["cod"] as? String else { return nil }
        let stopNumber = json["num"] as? Int
        var services: [Service] = Service.createRequiredInstances(from: json, arrayKey: "servicios") ?? []
        services = services.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending }
        let nameComponents = name.components(separatedBy: " esq. ")
        let title = nameComponents[0]
        var subtitle: String?
        if nameComponents.count > 1 {
            subtitle = nameComponents[1]
        }
        self.init(code: code, number: stopNumber, services: services, coordinate: CLLocationCoordinate2D(latitude: location[0], longitude: location[1]), title: title, subtitle: subtitle, commune: commune)
    }
    
    override var hashValue: Int {
        return code.hashValue ^ 420.hashValue
    }
    
    static func == (rhs: Stop, lhs: Stop) -> Bool {
        return rhs.code == lhs.code
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherStop = object as? Stop else { return false }
        return code == otherStop.code
    }
}

// MARK: - Bip spot
class BipSpot: TransantiagoAnnotation {
    let address: String?
    let operationHours: [OperationHours]
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, commune: String, address: String?, operationHours: [OperationHours]) {
        self.address = address
        self.operationHours = operationHours
        super.init(coordinate: coordinate, title: title, subtitle: subtitle, commune: commune)
    }
    
    convenience required init?(json: [String: Any]) {
        guard let type = json["type"] as? Int, type == 1,
            let commune = json["comuna"] as? String,
            let name = json["name"] as? String,
            let location = (json["pos"] as? [NSNumber]).map({ $0.toDoubleArray() }) else { return nil }
        let address = json["direccion"] as? String
        
        var operationHours: [OperationHours] = []
        if let operationHoursJSON = json["horarios"] as? [String] {
            for timeString in operationHoursJSON {
                let components = timeString.components(separatedBy: ": de ")
                if components.count <= 1 { continue }
                let rangeTitle = components[0]
                var rangeComponents = components[1].components(separatedBy: " a ")
                if rangeComponents.count == 1 {
                    rangeComponents = components[1].components(separatedBy: " - ")
                }
                var rangeStart = rangeComponents[0]
                if rangeStart.hasPrefix("0") {
                    rangeStart.remove(at: rangeStart.startIndex)
                }
                operationHours.append(OperationHours(rangeTitle: rangeTitle, start: rangeStart, end: rangeComponents.last!))
            }
        }
        
        self.init(coordinate: CLLocationCoordinate2D(latitude: location[0], longitude: location[1]), title: name.capitalized(with: Locale(identifier: "es-CL")), subtitle: nil, commune: commune, address: address?.capitalized, operationHours: operationHours)
    }
    
    override var hashValue: Int {
        return coordinate.latitude.hashValue ^ coordinate.longitude.hashValue ^ (title ?? "").hashValue
    }
    
    static func == (rhs: BipSpot, lhs: BipSpot) -> Bool {
        return rhs.coordinate.latitude == lhs.coordinate.latitude && rhs.coordinate.longitude == lhs.coordinate.longitude && rhs.title == lhs.title
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let lhs = object as? BipSpot else { return false }
        return coordinate.latitude == lhs.coordinate.latitude && coordinate.longitude == lhs.coordinate.longitude && title == lhs.title
    }
}

// MARK: - Metro station
class MetroStation: BipSpot {
    let lineNumber: Int = 1
    let lineColor: UIColor = .red
}

// MARK: - Service
struct Service: CreatableFromJSON {
    let name: String
    let color: UIColor
    let routes: [Route]?
    let destinationString: String?
    
    struct Route {
        enum Way: Int {
            case outbound = 1, inbound = 2
        }
        let way: Way
        let operationHours: [OperationHours]
        let destinationString: String
        let polyline: MKPolyline
        let stops: [Stop]
    }
    
    init(name: String, color: UIColor, routes: [Route]?, destinationString: String?) {
        self.name = name
        self.color = color
        self.routes = routes
        self.destinationString = destinationString
    }
    
    init?(json: [String: Any]) {
        // Creating directly from a single JSON dictionary instead of from an array of JSON dictionaries means we only have a partial representation of the Service
        guard let name = json["cod"] as? String,
            let colorString = json["color"] as? String,
            let destinationString = json["destino"] as? String else { return nil }
        
        self.init(name: name, color: UIColor(hexString: colorString), routes: nil, destinationString: destinationString)
    }
    
    init?(jsonDictionaries: [[String: Any]]) {
        // Creating from a multiple JSON dictionaries means we have all the data
        guard let name = jsonDictionaries[0]["cod"] as? String else { return nil }
        guard let colorString = jsonDictionaries[0]["color"] as? String else { return nil }
        
        var routes: [Route] = []
        for (index, json) in jsonDictionaries.enumerated() {
            guard let destinationString = json["destino"] as? String,
                let operationHoursJSON = json["horarios"] as? [[String: String]],
                let shapesJSON = json["shapes"] as? [[String: Any]],
                let stopsJSON = json["paradas"] as? [[String: Any]] else { return nil }
            
            let way: Route.Way = index == 0 ? .outbound : .inbound
            
            var operationHours: [OperationHours] = []
            for hoursJSON in operationHoursJSON {
                guard let rangeTitle = hoursJSON["tipoDia"], let rangeStart = hoursJSON["fin"], let rangeEnd = hoursJSON["inicio"] else { continue }
                operationHours.append(OperationHours(rangeTitle: rangeTitle, start: rangeStart, end: rangeEnd))
            }
            
            var coordinates: [CLLocationCoordinate2D] = []
            for shapeJSON in shapesJSON {
                guard let latString = shapeJSON["latShape"] as? String, let lonString = shapeJSON["lonShape"] as? String, let lat = CLLocationDegrees(latString), let lon = CLLocationDegrees(lonString) else { continue }
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            
            var stops: [Stop] = []
            for stopJSON in stopsJSON {
                guard let stop = Stop(json: stopJSON) else { continue }
                stops.append(stop)
            }
            
            routes.append(Route(way: way, operationHours: operationHours, destinationString: destinationString, polyline: polyline, stops: stops))
        }
        
        self.init(name: name, color: UIColor(hexString: colorString), routes: routes, destinationString: nil)
    }
}

extension Service: Equatable {
    static func ==(lhs: Service, rhs: Service) -> Bool {
        return lhs.name == rhs.name && lhs.destinationString == rhs.destinationString
    }
}

// MARK: - Operation hours
struct OperationHours {
    let rangeTitle: String
    let start: String
    let end: String
}

// MARK: - Stop prediction
struct StopPrediction {
    let timestamp: Date
    let stopCode: String
    let responseString: String
    let serviceResponses: [ServiceResponse]
    
    struct ServiceResponse {
        let type: ResponseType
        let serviceName: String
//        let serviceInfo: ServiceInfo?
//        let responseString: String
        let predictions: [Prediction]?
        
        enum ResponseType: Int {
            case twoPredictions = 00, onePrediction = 01, noPrediction = 9, noIncomingBuses = 10, outOfSchedule = 11
        }
        // deprecated?
        struct ServiceInfo {
            let serviceName: String
            let color: UIColor
            let directionString: String
            let way: Service.Route.Way
        }
        struct Prediction {
            let distance: Int
            let predictionString: String
            let licensePlate: String
        }
    }
}
