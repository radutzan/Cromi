//
//  Transantiago.swift
//  Transantiago
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit
import MapKit

protocol TransantiagoAPIErrorDelegate: class {
    func transantiagoFailingAPIsDidChange(_ apis: [Transantiago.APIType])
}

class Transantiago: NSObject {
    enum APIType: String {
        case mapAnnotations, stopPrediction, serviceInfo
    }
    
    static let get = Transantiago()
    weak var errorDelegate: TransantiagoAPIErrorDelegate?
    
    override init() {
        super.init()
        performTestRequests()
    }
    
    // MARK: - Requests
    func annotations(aroundCoordinate coordinate: CLLocationCoordinate2D, completion: @escaping ([Stop]?, [BipSpot]?, [MetroStation]?) -> ()) {
        let task = URLSession.shared.dataTask(with: URL(string: "https://www.transantiago.cl/restservice/rest/getpuntoparada?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&bip=1")!) { (data, response, error) in
            var stops: [Stop]?
            var bipSpots: [BipSpot]?
            var metroStations: [MetroStation]?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let baseArray = jsonObject as? [[String: Any]] else { return }
                
                self.failingAPIs.remove(.mapAnnotations)
                
                stops = []
                bipSpots = []
                metroStations = []
                for json in baseArray {
                    if let type = json["type"] as? Int, let name = json["name"] as? String, type == 1 {
                        if name.hasPrefix("METRO") {
                            if let metroStation = MetroStation(json: json) {
                                metroStations!.append(metroStation)
                            }
                        } else {
                            if let bipSpot = BipSpot(json: json) {
                                bipSpots!.append(bipSpot)
                            }
                        }
                    } else if let stop = Stop(json: json) {
                        stops!.append(stop)
                    }
                }
            }
            if let error = error {
                self.registerError(for: .mapAnnotations, code: nil, error: error)
            }
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                self.registerError(for: .mapAnnotations, code: response.statusCode, error: nil)
            }
            completion(stops, bipSpots, metroStations)
        }
        task.resume()
    }
    
    func prediction(forStopCode code: String, completion: @escaping (StopPrediction?) -> ()) {
        let task = URLSession.shared.dataTask(with: URL(string: "https://www.transantiago.cl/predictor/prediccion?codsimt=\(code)")!) { (data, response, error) in
            var prediction: StopPrediction?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let json = jsonObject as? [String: Any],
                    let stopCode = json["paradero"] as? String,
                    let responseString = json["respuestaParadero"] as? String,
                    let servicesRoot = json["servicios"] as? [String: Any],
                    let services = servicesRoot["item"] as? [[String: Any]] else { return }
                
                self.failingAPIs.remove(.stopPrediction)
                
                var serviceResponses: [StopPrediction.ServiceResponse] = []
                for service in services {
                    guard let responseCodeString = service["codigorespuesta"] as? String,
                        let responseCode = Int(responseCodeString),
                        let responseType = StopPrediction.ServiceResponse.ResponseType(rawValue: responseCode),
                        let serviceName = service["servicio"] as? String else { return }
                    
                    var predictions: [StopPrediction.ServiceResponse.Prediction]?
                    switch responseType {
                    case .onePrediction, .twoPredictions:
                        guard let distanceString1 = service["distanciabus1"] as? String,
                            let distance1 = Int(distanceString1),
                            let predictionString1 = service["horaprediccionbus1"] as? String,
                            let licensePlate1 = service["ppubus1"] as? String else { break }
                        let prediction1 = self.sanitize(prediction: predictionString1)
                        predictions = [StopPrediction.ServiceResponse.Prediction(distance: distance1, predictionString: prediction1, licensePlate: licensePlate1)]
                        
                        guard let distanceString2 = service["distanciabus2"] as? String,
                            let distance2 = Int(distanceString2),
                            let predictionString2 = service["horaprediccionbus2"] as? String,
                            let licensePlate2 = service["ppubus2"] as? String else { break }
                        let prediction2 = self.sanitize(prediction: predictionString2)
                        predictions?.append(StopPrediction.ServiceResponse.Prediction(distance: distance2, predictionString: prediction2, licensePlate: licensePlate2))
                        break
                        
                    default:
                        break
                    }
                    
                    serviceResponses.append(StopPrediction.ServiceResponse(type: responseType, serviceName: serviceName, predictions: predictions))
                }
                
                prediction = StopPrediction(timestamp: Date(), stopCode: stopCode, responseString: responseString, serviceResponses: serviceResponses)
            }
            if let error = error {
                self.registerError(for: .stopPrediction, code: nil, error: error)
            }
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                self.registerError(for: .stopPrediction, code: response.statusCode, error: nil)
            }
            completion(prediction)
        }
        task.resume()
    }
    
    func service(withName serviceName: String, completion: @escaping (Service?) -> ()) {
        let task = URLSession.shared.dataTask(with: URL(string: "https://www.transantiago.cl/restservice/rest/getrecorrido/\(serviceName)")!) { (data, response, error) in
            var service: Service?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let baseArray = jsonObject as? [[String: Any]] else { return }
                
                self.failingAPIs.remove(.serviceInfo)
                
                service = Service(jsonDictionaries: baseArray)
            }
            if let error = error {
                self.registerError(for: .serviceInfo, code: nil, error: error)
            }
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                self.registerError(for: .serviceInfo, code: response.statusCode, error: nil)
            }
            completion(service)
        }
        task.resume()
    }
    
    // MARK: - API checks
    private var failingAPIs: Set<APIType> = [] {
        didSet {
            errorDelegate?.transantiagoFailingAPIsDidChange(Array(failingAPIs))
        }
    }
    
    private func performTestRequests() {
        background {
            self.annotations(aroundCoordinate: CLLocationCoordinate2DMake(-33.425567, -70.614486)) { (_, _, _) in }
            self.prediction(forStopCode: "PA420") { (_) in }
            self.service(withName: "503") { (_) in }
        }
    }
    
    private func registerError(for type: APIType, code: Int? = nil, error: Error? = nil) {
        mainThread {
            print("Transantiago: Registered error for API type \(type.rawValue).")
            self.failingAPIs.insert(type)
        }
    }
    
    // MARK: - Utilities
    private func sanitize(prediction string: String) -> String {
        return string.replacingOccurrences(of: " 0", with: " ").replacingOccurrences(of: "Entre ", with: "").replacingOccurrences(of: "En menos de ", with: "~").replacingOccurrences(of: "Menos de ", with: "~").replacingOccurrences(of: "Mas de ", with: ">").replacingOccurrences(of: ". ", with: "").replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "Y", with: NSLocalizedString("to", comment: ""))
    }

}
