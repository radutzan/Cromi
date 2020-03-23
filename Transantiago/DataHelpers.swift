//
//  DataHelpers.swift
//  Cromi
//
//  Created by Radu Dutzan on 3/12/20.
//  Copyright © 2020 Radu Dutzan. All rights reserved.
//

import MapKit

// MARK: - Data source
protocol DataSource: AnyObject {
    associatedtype DataSourceType
    static var get: DataSourceType { get }
    
    // MARK: - Requests
    func annotations(aroundCoordinate coordinate: CLLocationCoordinate2D, completion: @escaping ([Stop]?, [BipSpot]?, [MetroStation]?) -> ())
    func prediction(forStopCode code: String, completion: @escaping (StopPrediction?) -> ())
    func service(with name: String, completion: @escaping (Service?) -> ())
}

// MARK: - Coordinate
class Coordinate: NSObject, NSCoding {
    var latitude: Double = 0
    var longitude: Double = 0
    var clRepresentation: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(clLocationCoordinate2D coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        super.init()
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        super.init()
    }
    
    required init?(coder decoder: NSCoder) {
        self.latitude = decoder.decodeDouble(forKey: "latitude")
        self.longitude = decoder.decodeDouble(forKey: "longitude")
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(latitude, forKey: "latitude")
        coder.encode(longitude, forKey: "longitude")
    }
}

// MARK: - Encoding structs
struct JSON {
    static let encoder = JSONEncoder()
}

// https://stackoverflow.com/questions/46597624/can-swift-convert-a-class-struct-data-into-dictionary
extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSON.encoder.encode(self))) as? [String: Any] ?? [:]
    }
}

// https://gist.github.com/freak4pc/98c813d8adb8feb8aee3a11d2da1373f
public extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: pointCount)

        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))

        return coords
    }
}
