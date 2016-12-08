//
//  Transantiago.swift
//  Transantiago
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit
import MapKit

class Transantiago: NSObject {
    
    static let get = Transantiago()
    
    // TODO: differentiate annotation types (should be "annotations aroundCoordinate")
    func stops(aroundCoordinate coordinate: CLLocationCoordinate2D, completion: @escaping ([StopAnnotation]?) -> (Void)) {
        let task = URLSession.shared.dataTask(with: URL(string: "https://www.transantiago.cl/restservice/rest/getpuntoparada?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&bip=1")!) { (data, response, error) in
            var stopAnnotations: [StopAnnotation]?
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                guard let baseArray = jsonObject as? [Any] else { return }
                
                print(baseArray)
                stopAnnotations = []
                for item in baseArray {
                    if let stopJSON = item as? [String: Any], let stopAnnotation = StopAnnotation(json: stopJSON) {
                        stopAnnotations!.append(stopAnnotation)
                    }
                }
            }
            completion(stopAnnotations)
        }
        task.resume()
    }
    
    func prediction(forStopCode: String, completion: @escaping (StopPrediction?) -> (Void)) {
        // http://www.transantiago.cl/predictor/prediccion?codsimt=PA420
    }

}
