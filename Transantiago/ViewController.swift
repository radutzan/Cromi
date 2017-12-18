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
        serviceBar.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handle(serviceBarPan:))))
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
    
    private func presentFeatureSpotlightIfNeeded() {
        let spotlightKey = "Live Buses Spotlight"//"Line View Spotlight"
        guard !UserDefaults.standard.bool(forKey: spotlightKey) else { return }
        
        let spotlightAlert = UIAlertController(title: NSLocalizedString("Feature Spotlight alert title", comment: ""), message: NSLocalizedString("Feature Spotlight alert message", comment: ""), preferredStyle: .alert)
        spotlightAlert.addAction(UIAlertAction(title: NSLocalizedString("Feature Spotlight alert confirmation", comment: ""), style: .default, handler: nil))
        present(spotlightAlert, animated: true, completion: nil)
        
        UserDefaults.standard.set(true, forKey: spotlightKey)
    }
    
    // MARK: - LocationServicesDelegate
    private var isNotInSantiago = false
    func locationServicesAuthorizedLocation() {
        locationServices.updateLocation() {
            self.mapController?.centerMapAroundUserLocation(animated: false)
            self.mapController?.placeAnnotations(aroundCoordinate: self.locationServices.userLocation) {
                self.mapController?.selectNearestStop()
            }
            delay(3) {
                guard !self.isNotInSantiago else { return }
                self.presentFeatureSpotlightIfNeeded()
            }
        }
    }
    
    func locationServicesUserOutsideSantiago() {
        isNotInSantiago = true
        let stgoAlert = UIAlertController(title: NSLocalizedString("Not in Santiago alert title", comment: ""), message: NSLocalizedString("Not in Santiago alert message", comment: ""), preferredStyle: .alert)
        stgoAlert.addAction(UIAlertAction(title: NSLocalizedString("Not in Santiago alert confirmation", comment: ""), style: .default, handler: { (action) in
            self.locationServices.forceSantiago = true
            self.mapController?.centerMapAroundUserLocation(animated: true)
            self.mapController?.placeAnnotations(aroundCoordinate: self.locationServices.userLocation)
            self.presentFeatureSpotlightIfNeeded()
        }))
        present(stgoAlert, animated: true, completion: nil)
    }
    
    @IBAction func locationButtonTapped(button: UIButton) {
        locationServices.updateLocation() {
            self.mapController?.centerMapAroundUserLocation(animated: true)
        }
    }
    
    // MARK: - Map interaction
    func signDidTapHeader(_ signView: StreetSignView) {
        guard let annotation = signView.annotation else { return }
        var coordinate = annotation.coordinate
        let spanMultiplier = signView.intrinsicContentSize.height / 580
        coordinate.latitude += Double(spanMultiplier) * 0.0014
        mapController?.centerMap(around: coordinate, animated: true)
    }
    
    private var storedCompleteService: Service?
    func signDidSelect(service: Service) {
        guard let stopInfo = service.stopInfo else { return }
        mapController?.reset(holdForNextService: true)
        presentServiceBar(service: service)
        present(service: service, direction: stopInfo.direction)
    }
    
    func serviceBarSelected(direction: Service.Route.Direction, service: Service) {
        present(service: service, direction: direction)
    }
    
    func serviceBarRequestedDismissal() {
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.allowUserInteraction], animations: {
            self.serviceBarHorizontalCenterConstraint.constant = self.view.bounds.width
            self.view.layoutIfNeeded()
        }) { finished in
            self.serviceBar.service = nil
        }
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
        if (storedCompleteService == nil || storedCompleteService?.routes == nil) && (service.routes != nil && service.routes!.count > 0) {
            storedCompleteService = service
        }
        guard let completeService = storedCompleteService, completeService.name == service.name, (completeService.routes ?? []).count > 0 else {
            SCLTransit.get.serviceRoutes(for: service) { (newService) in
                guard let newService = newService, let serviceRoutes = newService.routes, serviceRoutes.count > 0 else { return }
                mainThread {
                    print("got complete service \(newService.name)")
                    self.storedCompleteService = newService
                    guard self.serviceBar.service != nil else { return }
                    self.present(service: newService, direction: direction)
                }
            }
            return
        }
        
        serviceBar.service = completeService
        serviceBar.selectedDirection = direction
        mapController?.reset(holdForNextService: true)
        mapController?.display(service: completeService, direction: direction)
    }
    
    private var initialBarConstant: CGFloat = 0
    @objc private func handle(serviceBarPan pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            initialBarConstant = serviceBarHorizontalCenterConstraint.constant
        case .changed:
            var proposedTranslation = pan.translation(in: self.view).x
            if proposedTranslation < 0 {
                proposedTranslation /= 4
            }
            serviceBarHorizontalCenterConstraint.constant = initialBarConstant + proposedTranslation
        default:
            if serviceBarHorizontalCenterConstraint.constant > 80 || pan.velocity(in: self.view).x > 820 {
                serviceBarRequestedDismissal()
            } else {
                presentServiceBar(service: serviceBar.service!)
            }
            return
        }
    }

}
