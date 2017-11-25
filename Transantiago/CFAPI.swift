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
        print("CFAPI: Predicting at stop \(code)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            var prediction: StopPrediction?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let json = jsonObject as? [String: Any],
                    let estimationRoot = json["estimation"] as? [Any],
                    let estimations = estimationRoot[0] as? [[String]] else { return }
                
                var serviceResponses: [StopPrediction.ServiceResponse] = []
                
                var orderedEstimations: [String: [[String]]] = [:]
                for estimation in estimations {
                    let name = estimation[0].lowercased()
                    if orderedEstimations[name] != nil {
                        orderedEstimations[name]!.append(estimation)
                    } else {
                        orderedEstimations[name] = [estimation]
                    }
                }
                print(orderedEstimations)
                
                for (service, estimations) in orderedEstimations {
                    var predictions: [StopPrediction.ServiceResponse.Prediction]?
                    for estimation in estimations {
                        guard estimation.count == 3, let distance = Int(estimation[2]) else { continue }
                        if predictions == nil { predictions = [] }
                        let predictionString = self.sanitize(prediction: estimation[1])
                        predictions?.append(StopPrediction.ServiceResponse.Prediction(distance: distance, predictionString: predictionString, licensePlate: nil))
                    }
                    let responseKind: StopPrediction.ServiceResponse.Kind = predictions!.count == 1 ? .onePrediction : .twoPredictions
                    let response = StopPrediction.ServiceResponse(kind: responseKind, serviceName: service, predictions: predictions)
                    serviceResponses.append(response)
                }
                
                if let otherResponses = estimationRoot.last as? [String: String] {
                    for (key, value) in otherResponses {
                        let responseKind: StopPrediction.ServiceResponse.Kind = value == "fuera_de_horario" ? .outOfSchedule : .noPrediction
                        let response = StopPrediction.ServiceResponse(kind: responseKind, serviceName: key, predictions: nil)
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
        return string.replacingOccurrences(of: " 0", with: " ").replacingOccurrences(of: "Entre ", with: "").replacingOccurrences(of: "En menos de ", with: "~").replacingOccurrences(of: "Menos de ", with: "~").replacingOccurrences(of: "~ ", with: "~").replacingOccurrences(of: "Mas de ", with: ">").replacingOccurrences(of: ". ", with: "").replacingOccurrences(of: ".", with: "").replacingOccurrences(of: " Y ", with: "–").replacingOccurrences(of: " min", with: "'")
    }
}
