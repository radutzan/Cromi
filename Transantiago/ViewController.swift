//
//  ViewController.swift
//  Transantiago
//
//  Created by Radu Dutzan on 12/7/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var locationButton: UIButton!
    
    private var selectedAnnotation: TransantiagoAnnotation?
    private var scrollEventTimer: Timer?
    private let signView = StreetSignView()
    private let gradientLayer = CAGradientLayer()
    
    private let locationManager = CLLocationManager()
    private var locationAuthorized = false {
        didSet {
            guard locationAuthorized, !didSetInitialLocation else { return }
            locationManager.startUpdatingLocation()
        }
    }
    private var didSetInitialLocation = false
    private var currentCoordinate: CLLocationCoordinate2D?
    private var forceSantiago = false
    private var userLocation: CLLocationCoordinate2D {
        let defaultCoordinate = CLLocationCoordinate2DMake(-33.425567, -70.614486)
        if forceSantiago { return defaultCoordinate }
        return currentCoordinate ?? defaultCoordinate
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 200
        locationManager.requestWhenInUseAuthorization()
        
        locationButton.layer.backgroundColor = UIColor.white.cgColor
        locationButton.layer.cornerRadius = locationButton.bounds.width / 2
        locationButton.layer.shadowPath = UIBezierPath(roundedRect: locationButton.bounds, cornerRadius: locationButton.layer.cornerRadius).cgPath
        locationButton.layer.shadowOffset = CGSize(width: 0, height: 17)
        locationButton.layer.shadowRadius = 11
        locationButton.layer.shadowOpacity = 0.2
        
        gradientLayer.colors = [UIColor(red: 0.976, green: 0.961, blue: 0.929, alpha: 1).cgColor, UIColor(red: 0.976, green: 0.961, blue: 0.929, alpha: 0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        view.layer.addSublayer(gradientLayer)
        
        view.addSubview(signView)
        
        let displayLink = CADisplayLink(target: self, selector: #selector(updateSignFrameIfNeeded))
        displayLink.add(to: .main, forMode: .defaultRunLoopMode)
    }
    
    override func viewWillLayoutSubviews() {
        gradientLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: view.bounds.width, height: 40))
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentCoordinate = location.coordinate
        manager.stopUpdatingLocation()
        
        guard !didSetInitialLocation else { return }
        centerMapAroundUserLocation(animated: false)
        placeAnnotations(aroundCoordinate: mapView.centerCoordinate)
        
        // check if user is not in Santiago
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            guard let placemark = placemarks?.first, let administrativeArea = placemark.administrativeArea else { return }
            if administrativeArea != "Metropolitana de Santiago" {
                let stgoAlert = UIAlertController(title: NSLocalizedString("Not in Santiago alert title", comment: ""), message: NSLocalizedString("Not in Santiago alert message", comment: ""), preferredStyle: .alert)
                stgoAlert.addAction(UIAlertAction(title: NSLocalizedString("Not in Santiago alert confirmation", comment: ""), style: .default, handler: { (action) in
                    self.forceSantiago = true
                    self.centerMapAroundUserLocation(animated: true)
                    self.placeAnnotations(aroundCoordinate: self.userLocation)
                }))
                self.present(stgoAlert, animated: true, completion: nil)
            }
        }
        
        didSetInitialLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        placeAnnotations(aroundCoordinate: mapView.centerCoordinate)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? TransantiagoAnnotation else { return }
        selectedAnnotation = annotation
        view.image = pinImage(forAnnotation: annotation, selected: true)
        
        signView.annotation = annotation
        signView.present(fromCenter: point(forAnnotation: annotation), targetFrame: signFrame(forAnnotation: annotation))
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let oldAnnotation = view.annotation as? TransantiagoAnnotation else { return }
        view.image = pinImage(forAnnotation: oldAnnotation, selected: false)
        let transition = CATransition()
        transition.duration = 0.24
        transition.type = kCATransitionFade
        view.layer.add(transition, forKey: nil)
        selectedAnnotation = nil
        
        signView.dismiss(toCenter: point(forAnnotation: oldAnnotation))
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? TransantiagoAnnotation else { return nil }
        
        var reuseIdentifier = ""
        switch annotation {
        case is Stop:
            reuseIdentifier = "Stop pin"
        case is MetroStation:
            reuseIdentifier = "Metro pin"
        case is BipSpot:
            reuseIdentifier = "Bip pin"
        default:
            return nil
        }
        
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        annotationView.canShowCallout = false
        annotationView.image = pinImage(forAnnotation: annotation, selected: false)
        
        return annotationView
    }
    
    // MARK: - Pins and signs
    @objc private func updateSignFrameIfNeeded() {
        guard let selectedAnnotation = selectedAnnotation else { return }
        signView.frame = signFrame(forAnnotation: selectedAnnotation)
    }
    
    private var targetSignSize: CGSize {
        return signView.intrinsicContentSize
    }
    private let signDistance: CGFloat = 25
    
    private func point(forAnnotation annotation: MKAnnotation) -> CGPoint {
        return mapView.convert(annotation.coordinate, toPointTo: view).rounded()
    }
    
    private func signFrame(forAnnotation annotation: MKAnnotation) -> CGRect {
        let annotationPoint = point(forAnnotation: annotation)
        
        let protectedInsets = UIEdgeInsets(top: 30, left: 10, bottom: 10, right: 10)
        var proposedFrame = CGRect(size: targetSignSize, center: annotationPoint.offsetBy(dx: 0, dy: -targetSignSize.height / 2 - signDistance))
        
        if proposedFrame.minX < protectedInsets.left {
            proposedFrame.origin.x = protectedInsets.left
        }
        if proposedFrame.minY < protectedInsets.top {
            proposedFrame.origin.y = protectedInsets.top
        }
        if proposedFrame.maxX > view.bounds.width - protectedInsets.left {
            proposedFrame.origin.x = view.bounds.width - protectedInsets.left - proposedFrame.width
        }
        if proposedFrame.maxY > view.bounds.height - protectedInsets.bottom {
            proposedFrame.origin.x = view.bounds.height - protectedInsets.bottom - proposedFrame.height
        }
        
        return proposedFrame
    }
    
    private func pinImage(forAnnotation annotation: TransantiagoAnnotation, selected: Bool) -> UIImage? {
        var pinImage: UIImage?
        switch annotation {
        case is Stop:
            pinImage = selected ? #imageLiteral(resourceName: "pin paradero selected") : #imageLiteral(resourceName: "pin paradero")
        case is MetroStation:
            pinImage = selected ? #imageLiteral(resourceName: "pin metro selected") : #imageLiteral(resourceName: "pin metro")
        case is BipSpot:
            pinImage = selected ? #imageLiteral(resourceName: "pin bip selected") : #imageLiteral(resourceName: "pin bip")
        default:
            return nil
        }
        return pinImage
    }
    
    // MARK: - Helpers
    private func centerMapAroundUserLocation(animated: Bool) {
        let allowedSpan: CLLocationDegrees = 0.0025
        let userRegion = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: allowedSpan, longitudeDelta: allowedSpan))
        mapView.setRegion(userRegion, animated: animated)
    }
    
    private func placeAnnotations(aroundCoordinate coordinate: CLLocationCoordinate2D) {
        Transantiago.get.annotations(aroundCoordinate: coordinate) { (stops, bipSpots, metroStations) -> (Void) in
            guard let stops = stops, let bipSpots = bipSpots, let metroStations = metroStations else { return }
            mainThread {
                let currentAnnotationsSet = Set(self.mapView.annotations.filter { $0 is TransantiagoAnnotation } as! [TransantiagoAnnotation])
                let newAnnotationsSet = Set((stops as [TransantiagoAnnotation]) + (bipSpots as [TransantiagoAnnotation]) + (metroStations as [TransantiagoAnnotation]))
                let annotationsToRemove = Array(currentAnnotationsSet.subtracting(newAnnotationsSet))
                let annotationsToAdd = Array(newAnnotationsSet.subtracting(currentAnnotationsSet))
                
                self.mapView.removeAnnotations(annotationsToRemove)
                self.mapView.addAnnotations(annotationsToAdd)
            }
        }
    }
    
    @IBAction func locationButtonTapped() {
        centerMapAroundUserLocation(animated: true)
    }

}
