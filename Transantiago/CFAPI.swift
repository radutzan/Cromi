//
//  CFAPI.swift
//  Cromi
//
//  Created by Radu Dutzan on 10/19/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import MapKit

class CFAPI: NSObject, DataSource {
    static let get = CFAPI()
    
    func annotations(aroundCoordinate coordinate: CLLocationCoordinate2D, completion: @escaping ([Stop]?, [BipSpot]?, [MetroStation]?) -> ()) {
        
    }
    
    func prediction(forStopCode code: String, completion: @escaping (StopPrediction?) -> ()) {
        guard let requestURL = URL(string: "http://api.cuantofalta.mobi/bus_stops/estimate?parada=\(code)&codser=") else { return }
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            var prediction: StopPrediction?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let json = jsonObject as? [String: Any],
                    let stopData = json["bus_stop"] as? [String: Any],
                    let stopServices = stopData["recorridos"] as? [[String: String]],
                    let estimationRoot = json["estimation"] as? [Any],
                    let estimations = estimationRoot[0] as? [[String]] else { return }
                
                let otherResponses = estimationRoot.last as? [String: String]
                
                var serviceResponses: [StopPrediction.ServiceResponse] = []
                for serviceData in stopServices {
                    for (key, value) in serviceData {
                        guard key == "name" else { continue }
                        let serviceName = value
                        var predictions: [StopPrediction.ServiceResponse.Prediction]?
                        for estimation in estimations {
                            guard estimation.count == 3, estimation[0] == serviceName, let distance = Int(estimation[2]) else { continue }
                            if predictions == nil { predictions = [] }
                            let predictionString = self.sanitize(prediction: estimation[1])
                            predictions?.append(StopPrediction.ServiceResponse.Prediction(distance: distance, predictionString: predictionString, licensePlate: nil))
                        }
                        var responseKind: StopPrediction.ServiceResponse.Kind = predictions == nil ? .noPrediction : (predictions!.count == 1 ? .onePrediction : .twoPredictions)
                        if let otherResponses = otherResponses, predictions == nil {
                            for (key, value) in otherResponses {
                                guard key == serviceName else { continue }
                                if value == "fuera_de_horario" {
                                    responseKind = .outOfSchedule
                                }
                            }
                        }
                        let response = StopPrediction.ServiceResponse(kind: responseKind, serviceName: serviceName, predictions: predictions)
                        serviceResponses.append(response)
                    }
                }
                
                prediction = StopPrediction(timestamp: Date(), stopCode: code, responseString: nil, serviceResponses: serviceResponses)
            }
            completion(prediction)
        }
        task.resume()
    }
    
    func service(withName serviceName: String, completion: @escaping (Service?) -> ()) {
        
    }
    
    private func sanitize(prediction string: String) -> String {
        var string = string
        if string.contains(" Y ") {
            string.append(" min")
        }
        return string.replacingOccurrences(of: " 0", with: " ").replacingOccurrences(of: "Entre ", with: "").replacingOccurrences(of: "En menos de ", with: "~").replacingOccurrences(of: "Menos de ", with: "~").replacingOccurrences(of: "Mas de ", with: ">").replacingOccurrences(of: ". ", with: "").replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "Y", with: NSLocalizedString("to", comment: ""))
    }
}
