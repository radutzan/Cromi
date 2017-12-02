//
//  ViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/7/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import MapKit

class ViewController: UIViewController, MKMapViewDelegate, LocationServicesDelegate {
    
    let locationServices = LocationServices()
    var mapController: MapViewController?
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var buttonStackView: TouchTransparentStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationServices.delegate = self
        
        if let mapViewController = childViewControllers.first as? MapViewController {
            mapController = mapViewController
            mapController?.locationServices = locationServices
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - LocationServicesDelegate
    func locationServicesAuthorizedLocation() {
        locationServices.updateLocation() {
            self.mapController?.centerMapAroundUserLocation(animated: false)
            self.mapController?.placeAnnotations(aroundCoordinate: self.locationServices.userLocation) {
                self.mapController?.selectNearestStop()
            }
        }
    }
    
    func locationServicesUserOutsideSantiago() {
        let stgoAlert = UIAlertController(title: NSLocalizedString("Not in Santiago alert title", comment: ""), message: NSLocalizedString("Not in Santiago alert message", comment: ""), preferredStyle: .alert)
        stgoAlert.addAction(UIAlertAction(title: NSLocalizedString("Not in Santiago alert confirmation", comment: ""), style: .default, handler: { (action) in
            self.locationServices.forceSantiago = true
            self.mapController?.centerMapAroundUserLocation(animated: true)
            self.mapController?.placeAnnotations(aroundCoordinate: self.locationServices.userLocation)
        }))
        present(stgoAlert, animated: true, completion: nil)
    }
    
    @IBAction func locationButtonTapped() {
        locationServices.updateLocation() {
            self.mapController?.centerMapAroundUserLocation(animated: true)
        }
    }

}
