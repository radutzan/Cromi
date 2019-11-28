//
//  SCLTransit.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/3/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import RaduKit
import MapKit

class SCLTransit: NSObject, DataSource {
    static let get = SCLTransit()
    private let baseURLString = "https://api.scltrans.it"
    
    override init() {
        super.init()
        annotations(aroundCoordinate: CLLocationCoordinate2DMake(-33.425567, -70.614486)) { (_, _, _) in }
    }
    
    private func processStops(from stopsData: [[String : Any]]) -> (stops: [Stop], metroStations: [MetroStation]) {
        var stops: [Stop] = []
        var metroStations: [MetroStation] = []
        for dict in stopsData {
            guard let lat = dict["stop_lat"] as? String,
                let latDouble = Double(lat),
                let lon = dict["stop_lon"] as? String,
                let lonDouble = Double(lon),
                let code = dict["stop_code"] as? String,
                let agency = dict["agency_id"] as? String,
                let baseName = dict["stop_name"] as? String else { continue }
            
            if agency == "TS" {
                // name
                let nameComponents = baseName.replacingOccurrences(of: "\(code)-", with: "").replacingOccurrences(of: "(M)", with: "Metro").replacingOccurrences(of: "   ", with: " ").replacingOccurrences(of: "  ", with: " ").components(separatedBy: " / ")
                guard nameComponents.count > 1 else { continue }
                
                var stopNumber: Int?
                var title = nameComponents[0].replacingOccurrences(of: " Esq.", with: "")
                var subtitle: String?
                if nameComponents[0].hasPrefix("Parada") {
                    stopNumber = Int(nameComponents[0].replacingOccurrences(of: "Parada ", with: ""))
                    title = nameComponents[1]
                } else {
                    subtitle = nameComponents[1]
                }
                
                var services: [Service] = []
                if let servicesBase = dict["routes"] as? [[String: [String: Any]]], servicesBase.count > 0 {
                    for serviceBase in servicesBase {
                        guard let directionBase = serviceBase["direction"],
                            let routeBase = serviceBase["route"],
                            let name = directionBase["route_id"] as? String,
                            let headsign = directionBase["direction_headsign"] as? String,
                            let direction = directionBase["direction_id"] as? Int, direction < 2,
                            let colorString = routeBase["route_color"] as? String else { continue }
                        
                        services.append(Service(name: name, color: UIColor(hexString: colorString), routes: nil, stopInfo: Service.StopInfo(headsign: headsign.replacingOccurrences(of: "(M)", with: "Metro"), direction: Service.Route.Direction(rawValue: direction)!)))
                    }
                }
                
                stops.append(Stop(code: code, number: stopNumber, services: services, coordinate: CLLocationCoordinate2D(latitude: latDouble, longitude: lonDouble), title: title, subtitle: subtitle, commune: ""))
                
            } else if agency == "M" {
                metroStations.append(MetroStation(coordinate: CLLocationCoordinate2D(latitude: latDouble, longitude: lonDouble), title: baseName, subtitle: nil, commune: "", address: nil, operationHours: []))
            }
        }
        
        return (stops, metroStations)
    }
    
    func annotations(aroundCoordinate coordinate: CLLocationCoordinate2D, completion: @escaping ([Stop]?, [BipSpot]?, [MetroStation]?) -> ()) {
        guard let requestURL = URL(string: baseURLString + "/v1/map?center_lat=\(coordinate.latitude)&center_lon=\(coordinate.longitude)&include_bip_spots=1&include_stop_routes=1") else { return }
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
                
                let stopsResult = self.processStops(from: stopsData)
                stops = stopsResult.stops
                metroStations = stopsResult.metroStations
            }
            if let error = error {
                print("SCLTransit: Map annotations request failed with error: \(error)")
            }
            completion(stops, bipSpots, metroStations)
        }
        task.resume()
    }
    
    func prediction(forStopCode code: String, completion: @escaping (StopPrediction?) -> ()) {
        guard let requestURL = URL(string: baseURLString + "/v1/stops/\(code)/next_arrivals") else { return }
        print("SCLTransit: Requesting \(requestURL.absoluteString)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            var prediction: StopPrediction?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let base = jsonObject as? [String: [[String: Any]]],
                    let results = base["results"], results.count > 0 else { return }
                
                var serviceResponses: [StopPrediction.ServiceResponse] = []
                
                var orderedEstimations: [String: [[String: Any]]] = [:]
                for result in results {
                    guard let serviceName = result["route_id"] as? String else { continue }
                    if orderedEstimations[serviceName] != nil {
                        orderedEstimations[serviceName]!.append(result)
                    } else {
                        orderedEstimations[serviceName] = [result]
                    }
                }
//                print(orderedEstimations)
                
                for (serviceName, estimations) in orderedEstimations {
                    var responseKind: StopPrediction.ServiceResponse.Kind = .noPrediction
                    var predictions: [StopPrediction.ServiceResponse.Prediction]?
                    for estimation in estimations {
                        guard let predictionString = estimation["arrival_estimation"]as? String else { continue }
                        guard let distanceString = estimation["bus_distance"] as? String, let distance = Int(distanceString) else {
                            if predictionString.contains("Servicio fuera de horario") {
                                responseKind = .outOfSchedule
                            }
                            if predictionString.contains("No hay buses") {
                                responseKind = .noIncomingBuses
                            }
                            continue
                        }
                        if predictions == nil { predictions = [] }
                        predictions?.append(StopPrediction.ServiceResponse.Prediction(distance: distance, predictionString: self.sanitize(prediction: predictionString), licensePlate: estimation["bus_plate_number"] as? String))
                    }
                   
                    if let predictions = predictions, predictions.count > 0 {
                        responseKind = predictions.count == 1 ? .onePrediction : .twoPredictions
                    }
                    serviceResponses.append(StopPrediction.ServiceResponse(kind: responseKind, serviceName: serviceName, predictions: predictions))
                }
                
                prediction = StopPrediction(timestamp: Date(), stopCode: code, responseString: nil, serviceResponses: serviceResponses)
            }
            if let error = error {
                print("SCLTransit: Prediction  request failed with error: \(error)")
            }
            completion(prediction)
        }
        task.resume()
    }
    
    func service(withName serviceName: String, completion: @escaping (Service?) -> ()) {
//        guard let requestURL = URL(string: baseURLString + "/v1/routes/\(serviceName)/directions") else { return }
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
        guard let requestURL = URL(string: baseURLString + "/v2/routes/\(service.name)/directions") else { return }
        let startTime = CACurrentMediaTime()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        print("SCLTransit: Requesting \(requestURL.absoluteString)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            var newService: Service?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let base = jsonObject as? [String: [[String: Any]]],
                    let results = base["results"], results.count > 0 else { return }
                var routes = Array<Service.Route>()
                for routeBase in results {
                    guard let headsign = routeBase["direction_headsign"] as? String,
                        let direction = routeBase["direction_id"] as? Int, direction < 2,
                        let shapeData = routeBase["shape"] as? [[String: Any]],
                        let stopTimesData = routeBase["stop_times"] as? [[String: Any]] else { continue }
                    
                    var coordinates: [CLLocationCoordinate2D] = []
                    for data in shapeData {
                        guard let latString = data["shape_pt_lat"] as? String, let lonString = data["shape_pt_lon"] as? String, let lat = CLLocationDegrees(latString), let lon = CLLocationDegrees(lonString) else { continue }
                        coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                    }
                    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                    
                    var stopCodes: [String] = []
                    for data in stopTimesData {
                        guard let stopCode = data["stop_id"] as? String else { continue }
                        stopCodes.append(stopCode)
                    }
                    routes.append(Service.Route(direction: Service.Route.Direction(rawValue: direction)!, operationHours: [], headsign: headsign.replacingOccurrences(of: "(M)", with: "Metro"), polyline: polyline, stops: nil, stopCodes: stopCodes))
                }
                newService = Service(name: service.name, color: service.color, routes: routes, stopInfo: nil)
            }
            if let error = error {
                print("SCLTransit: Service routes request failed with error: \(error)")
            }
            mainThread {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                print("SCLTransit: Delivering service routes after \(CACurrentMediaTime() - startTime) seconds.")
                completion(newService)
            }
        }
        task.resume()
    }
    
    func buses(forService serviceName: String, direction: Service.Route.Direction, completion: @escaping ([Bus]?) -> ()) {
        guard let requestURL = URL(string: baseURLString + "/v1/buses?route_id=\(serviceName)&direction_id=\(direction.rawValue)") else { return }
        print("SCLTransit: Requesting \(requestURL.absoluteString)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            var buses: [Bus]?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let base = jsonObject as? [String: Any],
                    let results = base["results"] as? [[String: Any]] else { return }
                buses = []
                for result in results {
                    guard let lat = result["bus_lat"] as? String,
                        let latDouble = Double(lat),
                        let lon = result["bus_lon"] as? String,
                        let lonDouble = Double(lon),
                        let plateNumber = result["bus_plate_number"] as? String,
                        let service = result["route_id"] as? String else { continue }
                    buses?.append(Bus(plateNumber: plateNumber, serviceName: service, coordinate: CLLocationCoordinate2D(latitude: latDouble, longitude: lonDouble)))
                }
            }
            if let error = error {
                print("SCLTransit: Live buses request failed with error: \(error)")
            }
            completion(buses)
        }
        task.resume()
    }
    
    private func sanitize(prediction string: String) -> String {
        var string = string
        if string.contains(" Y ") {
            string.append(" min")
        }
        return string.replacingOccurrences(of: " 0", with: " ").replacingOccurrences(of: "Entre ", with: "").replacingOccurrences(of: "En menos de ", with: "~").replacingOccurrences(of: "Menos de ", with: "~").replacingOccurrences(of: "~ ", with: "~").replacingOccurrences(of: "Mas de ", with: ">").replacingOccurrences(of: ". ", with: "").replacingOccurrences(of: ".", with: "").replacingOccurrences(of: " Y ", with: "–").replacingOccurrences(of: " min", with: "'")
    }
}
