//
//  TSAPI Models.swift
//  Cromi
//
//  Created by Radu Dutzan on 10/18/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import MapKit

class TSAPIStop: Stop, CreatableFromJSON {
    convenience required init?(json: [String: Any]) {
        guard let type = json["type"] as? Int, type == 0,
            let commune = json["comuna"] as? String,
            let name = json["name"] as? String,
            let location = (json["pos"] as? [NSNumber]).map({ $0.toDoubleArray() }),
            let code = json["cod"] as? String else { return nil }
        let stopNumber = json["num"] as? Int
        var services: [Service] = TSAPIService.createRequiredInstances(from: json, arrayKey: "servicios") ?? []
        services = services.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending }
        let nameComponents = name.components(separatedBy: " esq. ")
        let title = nameComponents[0]
        var subtitle: String?
        if nameComponents.count > 1 {
            subtitle = nameComponents[1]
        }
        self.init(code: code, number: stopNumber, services: services, coordinate: CLLocationCoordinate2D(latitude: location[0], longitude: location[1]), title: title, subtitle: subtitle, commune: commune)
    }
}

class TSAPIBipSpot: BipSpot {
    static func from(json: [String: Any], metro: Bool) -> BipSpot? {
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
        
        if metro {
            return MetroStation(coordinate: CLLocationCoordinate2D(latitude: location[0], longitude: location[1]), title: name.capitalized(with: Locale(identifier: "es-CL")), subtitle: nil, commune: commune, address: address?.capitalized, operationHours: operationHours)
        } else {
            return BipSpot(coordinate: CLLocationCoordinate2D(latitude: location[0], longitude: location[1]), title: name.capitalized(with: Locale(identifier: "es-CL")), subtitle: nil, commune: commune, address: address?.capitalized, operationHours: operationHours)
        }
    }
}

class TSAPIService: Service, CreatableFromJSON {
    convenience required init?(json: [String: Any]) {
        // Creating directly from a single JSON dictionary instead of from an array of JSON dictionaries means we only have a partial representation of the Service
        guard let name = json["cod"] as? String,
            let colorString = json["color"] as? String,
            let destinationString = json["destino"] as? String else { return nil }
        
        let finalDestination = NSLocalizedString("to", comment: "") + String(destinationString[destinationString.index(after: destinationString.startIndex)...])//destinationString.suffix(from: destinationString.index(after: destinationString.startIndex))
        self.init(name: name, color: UIColor(hexString: colorString), routes: nil, destinationString: finalDestination)
    }
    
    convenience required init?(jsonDictionaries: [[String: Any]]) {
        // Creating from a multiple JSON dictionaries means we have all the data
        guard jsonDictionaries.count > 0, let name = jsonDictionaries[0]["cod"] as? String else { return nil }
        guard let colorString = jsonDictionaries[0]["color"] as? String else { return nil }
        
        var routes: [Route] = []
        for (index, json) in jsonDictionaries.enumerated() {
            guard let destinationString = json["destino"] as? String,
                let operationHoursJSON = json["horarios"] as? [[String: String]],
                let shapesJSON = json["shapes"] as? [[String: Any]],
                let stopsJSON = json["paradas"] as? [[String: Any]] else { return nil }
            
            let direction: Route.Direction = index == 0 ? .outbound : .inbound
            
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
                guard let stop = TSAPIStop(json: stopJSON) else { continue }
                stops.append(stop)
            }
            
            routes.append(Route(direction: direction, operationHours: operationHours, headsign: destinationString, polyline: polyline, stops: stops, stopCodes: []))
        }
        
        self.init(name: name, color: UIColor(hexString: colorString), routes: routes, destinationString: nil)
    }
}
