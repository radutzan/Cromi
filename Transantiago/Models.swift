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
        guard let type = json["type"] as? Int, type == 0 else { return nil }
        guard let commune = json["comuna"] as? String else { return nil }
        guard let name = json["name"] as? String else { return nil }
        guard let location = (json["pos"] as? [NSNumber]).map({ $0.toDoubleArray() }) else { return nil }
        guard let code = json["cod"] as? String else { return nil }
        let stopNumber = json["num"] as? Int
        let services: [Service] = Service.createRequiredInstances(from: json, arrayKey: "servicios") ?? []
        self.init(code: code, number: stopNumber, services: services, coordinate: CLLocationCoordinate2D(latitude: location[0], longitude: location[1]), title: name, subtitle: nil, commune: commune)
    }
    
}

class BipSpot: TransantiagoAnnotation {
    
    let address: String
    let operationHours: [OperationHours]
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, commune: String, address: String, operationHours: [OperationHours]) { 
        self.address = address
        self.operationHours = operationHours
        super.init(coordinate: coordinate, title: title, subtitle: subtitle, commune: commune)
    }
    
    convenience required init?(json: [String: Any]) {
        guard let type = json["type"] as? Int, type == 1 else { return nil }
        guard let commune = json["comuna"] as? String else { return nil }
        guard let name = json["name"] as? String else { return nil }
        guard let location = (json["pos"] as? [NSNumber]).map({ $0.toDoubleArray() }) else { return nil }
        // TODO: operation hours and address
        self.init(coordinate: CLLocationCoordinate2D(latitude: location[0], longitude: location[1]), title: name.capitalized(with: Locale(identifier: "es-CL")), subtitle: nil, commune: commune, address: "", operationHours: [])
    }
    
}

class MetroStation: BipSpot {
    
    
    
}

struct Service: CreatableFromJSON {
    
    let name: String
    let color: UIColor
    let routes: [Route]?
    let destinationString: String?
    
    struct Route {
        enum Way {
            case outbound, inbound
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
        guard let name = json["cod"] as? String else { return nil }
        guard let colorString = json["color"] as? String else { return nil }
        guard let destinationString = json["destino"] as? String else { return nil }
        
        self.init(name: name, color: UIColor(hexString: colorString), routes: nil, destinationString: destinationString)
    }
    
    init?(jsonDictionaries: [[String: Any]]) {
        // Creating from a multiple JSON dictionaries means we have all the data
        guard let name = jsonDictionaries[0]["cod"] as? String else { return nil }
        guard let colorString = jsonDictionaries[0]["color"] as? String else { return nil }
        
        var routes: [Route] = []
        for (index, json) in jsonDictionaries.enumerated() {
            guard let destinationString = json["destino"] as? String else { return nil }
            guard let operationHoursJSON = json["horarios"] as? [[String: String]] else { return nil }
            guard let shapesJSON = json["shapes"] as? [[String: Any]] else { return nil }
            guard let stopsJSON = json["paradas"] as? [[String: Any]] else { return nil }
            
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
struct OperationHours {
    let rangeTitle: String
    let start: String
    let end: String
}

struct StopPrediction {
    
    let stop: Stop
    
}
