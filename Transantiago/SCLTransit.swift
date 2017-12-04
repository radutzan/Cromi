//
//  SCLTransit.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/3/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import MapKit

class SCLTransit: NSObject, DataSource {
    static let get = SCLTransit()
    
    override init() {
        super.init()
        annotations(aroundCoordinate: CLLocationCoordinate2DMake(-33.425567, -70.614486)) { (_, _, _) in }
    }
    
    func annotations(aroundCoordinate coordinate: CLLocationCoordinate2D, completion: @escaping ([Stop]?, [BipSpot]?, [MetroStation]?) -> ()) {
        guard let requestURL = URL(string: "https://api.scltrans.it/v1/map?center_lat=\(coordinate.latitude)&center_lon=\(coordinate.longitude)&include_bip_spots=1&include_stop_routes=1") else { return }
        print("SCLTransit: Requesting \(requestURL.absoluteString)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            var stops: [Stop]?
            var bipSpots: [BipSpot]?
            var metroStations: [MetroStation]?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let base = jsonObject as? [String: [String: [Any]]],
                    let results = base["results"],
                    let bipData = results["bip_spots"] as? [[String: Any]],
                    let stopsData = results["stops"] as? [[String: Any]] else { return }
                
                bipSpots = []
                for dict in bipData {
                    guard let lat = dict["bip_spot_lat"] as? String,
                        let latDouble = Double(lat),
                        let lon = dict["bip_spot_lon"] as? String,
                        let lonDouble = Double(lon),
                        let address = dict["bip_spot_address"] as? String,
                        let code = dict["bip_spot_code"] as? String,
                        let entity = dict["bip_spot_entity"] as? String,
                        let baseName = dict["bip_spot_fantasy_name"] as? String else { continue }
                    
                    var name = baseName.localizedCapitalized
                    let codePrefix = "\(code)-"
                    if baseName.hasPrefix(codePrefix) {
                        name = name.replacingOccurrences(of: codePrefix, with: "")
                    }
                    if entity == "Servipag" {
                        name = "\(entity) \(name)"
                    }
                    
                    var operationHours: [OperationHours] = []
                    if let schedule = dict["bip_opening_time"] as? String {
                        let components = schedule.components(separatedBy: " - ")
                        for component in components {
                            let componentComponents = component.components(separatedBy: ": ")
                            // "Lun a Vie 8:00 a 19:00 Sab 9:00 a 17:00" @ bip code 849 😡
                            guard componentComponents.count > 1 else { continue }
                            let timeComponents = componentComponents[1].components(separatedBy: " a ")
                            guard timeComponents.count > 1 else { continue }
                            operationHours.append(OperationHours(rangeTitle: componentComponents[0], start: timeComponents[0], end: timeComponents[1]))
                        }
                    }
                    
                    bipSpots?.append(BipSpot(coordinate: CLLocationCoordinate2D(latitude: latDouble, longitude: lonDouble), title: name, subtitle: nil, commune: "", address: address.localizedCapitalized, operationHours: operationHours))
                }
                
                stops = []
                metroStations = []
                for dict in stopsData {
                    guard let lat = dict["stop_lat"] as? String,
                        let latDouble = Double(lat),
                        let lon = dict["stop_lon"] as? String,
                        let lonDouble = Double(lon),
                        let code = dict["stop_code"] as? String,
                        let servicesBase = dict["routes"] as? [[String: [String: Any]]], servicesBase.count > 0,
                        let firstRoute = servicesBase[0]["route"], let agency = firstRoute["agency_id"] as? String,
                        let baseName = dict["stop_name"] as? String else { continue }
                    
                    if agency == "TS" {
                        // name
                        let nameComponents = baseName.replacingOccurrences(of: "\(code)-", with: "").replacingOccurrences(of: "  ", with: " ").replacingOccurrences(of: "(M)", with: "Metro").components(separatedBy: " / ")
                        guard nameComponents.count > 1 else { continue }
                        
                        var stopNumber: Int?
                        var title = nameComponents[0].replacingOccurrences(of: " Esq.", with: "")
                        var subtitle: String?
                        if nameComponents[0].hasPrefix("Parada ") {
                            stopNumber = Int(nameComponents[0].replacingOccurrences(of: "Parada ", with: ""))
                            title = nameComponents[1]
                        } else {
                            subtitle = nameComponents[1]
                        }
                        
                        var services: [Service] = []
                        for serviceBase in servicesBase {
                            guard let directionBase = serviceBase["direction"],
                                let routeBase = serviceBase["route"],
                                let name = directionBase["route_id"] as? String,
                                let headsign = directionBase["direction_headsign"] as? String,
                                let direction = directionBase["direction_id"] as? Int, direction < 2,
                                let colorString = routeBase["route_color"] as? String else { continue }
                            
                            services.append(Service(name: name, color: UIColor(hexString: colorString), routes: nil, stopInfo: Service.StopInfo(headsign: headsign.replacingOccurrences(of: "(M)", with: "Metro"), direction: Service.Route.Direction(rawValue: direction)!)))
                        }
                        
                        stops?.append(Stop(code: code, number: stopNumber, services: services, coordinate: CLLocationCoordinate2D(latitude: latDouble, longitude: lonDouble), title: title, subtitle: subtitle, commune: ""))
                        
                    } else if agency == "M" {
                        metroStations?.append(MetroStation(coordinate: CLLocationCoordinate2D(latitude: latDouble, longitude: lonDouble), title: baseName, subtitle: nil, commune: "", address: nil, operationHours: []))
                    }
                }
            }
            if let error = error {
                print("SCLTransit: Map annotations request failed with error: \(error)")
            }
            completion(stops, bipSpots, metroStations)
        }
        task.resume()
    }
    
    func prediction(forStopCode code: String, completion: @escaping (StopPrediction?) -> ()) {
        
    }
    
    func service(withName serviceName: String, completion: @escaping (Service?) -> ()) {
//        guard let requestURL = URL(string: "https://api.scltrans.it/v1/routes/\(serviceName)/directions") else { return }
//        print("SCLTransit: Requesting \(requestURL.absoluteString)")
//        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
//            var service: Service?
//            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
////                service = Service(name: serviceName, color: <#T##UIColor#>, routes: <#T##[Service.Route]?#>, stopData: nil)
//            }
//            if let error = error {
//                print("SCLTransit: Service routes request failed with error: \(error)")
//            }
//            mainThread {
//                completion(service)
//            }
//        }
//        task.resume()
    }
    
    func serviceRoutes(for service: Service, completion: @escaping (Service?) -> ()) {
        guard let requestURL = URL(string: "https://api.scltrans.it/v1/routes/\(service.name)/directions") else { return }
        print("SCLTransit: Requesting \(requestURL.absoluteString)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            var newService: Service?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let base = jsonObject as? [String: [[String: Any]]],
                    let results = base["results"], results.count > 1 else { return }
                var routes = Array<Service.Route>()
                for routeBase in results {
                    guard let headsign = routeBase["direction_headsign"] as? String,
                        let direction = routeBase["direction_id"] as? Int, direction < 2,
                        let shapeData = routeBase["shape"] as? [[String: Any]],
                        let stopsData = routeBase["stop_times"] as? [[String: Any]] else { continue }
                    
                    var coordinates: [CLLocationCoordinate2D] = []
                    for data in shapeData {
                        guard let latString = data["shape_pt_lat"] as? String, let lonString = data["shape_pt_lon"] as? String, let lat = CLLocationDegrees(latString), let lon = CLLocationDegrees(lonString) else { continue }
                        coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                    }
                    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                    
                    var stops: [Stop] = []
                    for data in stopsData {
                        // TODO: merge with above when agency_id is fixed on API
                        guard let stopData = data["stop"] as? [String: Any],
                            let lat = stopData["stop_lat"] as? String,
                            let latDouble = Double(lat),
                            let lon = stopData["stop_lon"] as? String,
                            let lonDouble = Double(lon),
                            let code = stopData["stop_code"] as? String,
                            let baseName = stopData["stop_name"] as? String else { continue }
                        
                            let nameComponents = baseName.replacingOccurrences(of: "\(code)-", with: "").replacingOccurrences(of: "  ", with: " ").replacingOccurrences(of: "(M)", with: "Metro").components(separatedBy: " / ")
                            guard nameComponents.count > 1 else { continue }
                            
                            var stopNumber: Int?
                            var title = nameComponents[0].replacingOccurrences(of: " Esq.", with: "")
                            var subtitle: String?
                            if nameComponents[0].hasPrefix("Parada ") {
                                stopNumber = Int(nameComponents[0].replacingOccurrences(of: "Parada ", with: ""))
                                title = nameComponents[1]
                            } else {
                                subtitle = nameComponents[1]
                            }
                            
                            stops.append(Stop(code: code, number: stopNumber, services: [], coordinate: CLLocationCoordinate2D(latitude: latDouble, longitude: lonDouble), title: title, subtitle: subtitle, commune: ""))
                    }
                    
                    routes.append(Service.Route(direction: Service.Route.Direction(rawValue: direction)!, operationHours: [], headsign: headsign, polyline: polyline, stops: stops))
                }
                newService = Service(name: service.name, color: service.color, routes: routes, stopInfo: nil)
            }
            if let error = error {
                print("SCLTransit: Service routes request failed with error: \(error)")
            }
            mainThread {
                completion(newService)
            }
        }
        task.resume()
    }
    
    func buses(forService serviceName: String, direction: Service.Route.Direction, completion: @escaping ([Bus]?) -> ()) {
        guard let requestURL = URL(string: "https://api.scltrans.it/v1/buses?route_id=\(serviceName)&direction_id=\(direction.rawValue)") else { return }
        print("SCLTransit: Requesting \(requestURL.absoluteString)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            var buses: [Bus]?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
            }
            if let error = error {
                print("SCLTransit: Live buses request failed with error: \(error)")
            }
            completion(buses)
        }
        task.resume()
        
    }
}
