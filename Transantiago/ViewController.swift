//
//  ViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/7/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import MapKit

class ViewController: UIViewController, MKMapViewDelegate, LocationServicesDelegate, MapViewControllerDelegate, ServiceBarDelegate {
    
    
    let locationServices = LocationServices()
    var mapController: MapViewController?
    
    @IBOutlet var buttonRow: ButtonRow!
    @IBOutlet var serviceBar: ServiceBar!
    @IBOutlet var serviceBarHorizontalCenterConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonRow.buttons = [Button(image: #imageLiteral(resourceName: "button location"), title: NSLocalizedString("Location button", comment: ""), action: locationButtonTapped(button:))]
        locationServices.delegate = self
        serviceBar.delegate = self
        serviceBarHorizontalCenterConstraint.constant = view.bounds.width
        
        if let mapViewController = childViewControllers.first as? MapViewController {
            mapController = mapViewController
            mapController?.locationServices = locationServices
            mapController?.delegate = self
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
    
    @IBAction func locationButtonTapped(button: UIButton) {
        locationServices.updateLocation() {
            self.mapController?.centerMapAroundUserLocation(animated: true)
        }
    }
    
    // MARK: - Map interaction
    private var storedCompleteService: Service?
    func signDidSelect(service: Service) {
        guard let stopInfo = service.stopInfo else { return }
        presentServiceBar(service: service)
        present(service: service, direction: stopInfo.direction)
    }
    
    func serviceBarSelected(direction: Service.Route.Direction, service: Service) {
        present(service: service, direction: direction)
    }
    
    func serviceBarRequestedDismissal() {
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.serviceBarHorizontalCenterConstraint.constant = self.view.bounds.width
            self.view.layoutIfNeeded()
        }, completion: nil)
        mapController?.reset()
    }
    
    private func presentServiceBar(service: Service) {
        serviceBar.service = service
        UIView.animate(withDuration: 0.72, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: [], animations: {
            self.serviceBarHorizontalCenterConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func present(service: Service, direction: Service.Route.Direction) {
        if (storedCompleteService == nil || storedCompleteService?.routes == nil) && (service.routes != nil && service.routes!.count > 1) {
            storedCompleteService = service
        }
        guard let completeService = storedCompleteService, completeService.name == service.name, completeService.outboundRoute != nil, completeService.inboundRoute != nil else {
            SCLTransit.get.serviceRoutes(for: service) { (newService) in
                guard let newService = newService, let serviceRoutes = newService.routes, serviceRoutes.count > 1 else { return }
                mainThread {
                    print("got complete service \(newService.name)")
                    self.storedCompleteService = newService
                    self.present(service: newService, direction: direction)
                }
            }
            return
        }
        
        serviceBar.service = completeService
        mapController?.reset()
        mapController?.display(service: completeService, direction: direction)
    }

}
