//
//  LocationServices.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/2/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import CoreLocation

protocol LocationServicesDelegate: AnyObject {
    func locationServicesAuthorizedLocation()
    func locationServicesUserOutsideSantiago()
}

class LocationServices: NSObject, CLLocationManagerDelegate {
    weak var delegate: LocationServicesDelegate?
    
    private let locationManager = CLLocationManager()
    private(set) var isLocationAuthorized = false {
        didSet {
            guard isLocationAuthorized, !didSetInitialLocation else { return }
            delegate?.locationServicesAuthorizedLocation()
            self.didSetInitialLocation = true
        }
    }
    private var didSetInitialLocation = false
    
    private var currentCoordinate: CLLocationCoordinate2D?
    var forceSantiago = false
    var userLocation: CLLocationCoordinate2D {
        let defaultCoordinate = CLLocationCoordinate2DMake(-33.425567, -70.614486)
        if forceSantiago { return defaultCoordinate }
        return currentCoordinate ?? defaultCoordinate
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 200
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - CLLocationManagerDelegate
    private var needsLocationUpdate = false
    private var locationUpdateCompletionHandler: (() -> ())?
    func updateLocation(completion: (() -> ())? = nil) {
        guard isLocationAuthorized else { return }
        forceSantiago = false
        needsLocationUpdate = true
        locationManager.startUpdatingLocation()
        locationUpdateCompletionHandler = completion
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard needsLocationUpdate, let location = locations.last else { return }
        currentCoordinate = location.coordinate
        manager.stopUpdatingLocation()
        
        needsLocationUpdate = false
        locationUpdateCompletionHandler?()
        locationUpdateCompletionHandler = nil
        
        // check if user is not in Santiago
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            guard let placemark = placemarks?.first, let administrativeArea = placemark.administrativeArea else { return }
            if !administrativeArea.localizedCaseInsensitiveContains("santiago") {
                self.delegate?.locationServicesUserOutsideSantiago()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        isLocationAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
    }
}
