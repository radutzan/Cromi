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
    
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    private var userLocation: CLLocationCoordinate2D {
        return currentCoordinate ?? CLLocationCoordinate2DMake(-33.425567, -70.614486)
    }
    private var locationAuthorized = false {
        didSet {
            guard locationAuthorized, !didSetInitialLocation else { return }
            locationManager.startUpdatingLocation()
        }
    }
    private var didSetInitialLocation = false
    
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
        
        view.addSubview(signView)
        
        let displayLink = CADisplayLink(target: self, selector: #selector(updateSignFrameIfNeeded))
        displayLink.add(to: .main, forMode: .defaultRunLoopMode)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        currentCoordinate = coordinate
        manager.stopUpdatingLocation()
        
        guard !didSetInitialLocation else { return }
        centerMapAroundUserLocation(animated: false)
        didSetInitialLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // this could be more efficient, maybe
        placeAnnotations(aroundCoordinate: mapView.centerCoordinate)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? TransantiagoAnnotation else { return }
        selectedAnnotation = annotation
        view.image = pinImage(forAnnotation: annotation, selected: true)
        
        signView.annotation = annotation
        signView.frame = CGRect(size: targetSignSize, center: point(forAnnotation: annotation))
        
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.signView.alpha = 1
            self.signView.frame = self.signFrame(forAnnotation: annotation)
        }, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let oldAnnotation = view.annotation as? TransantiagoAnnotation else { return }
        view.image = pinImage(forAnnotation: oldAnnotation, selected: false)
        selectedAnnotation = nil
        
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.signView.alpha = 0
            self.signView.center = self.point(forAnnotation: oldAnnotation)
        }) { (finished) in
            
        }
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
    private func clearTransantiagoAnnotations(in mapView: MKMapView) {
        let transantiagoAnnotations = mapView.annotations.filter { $0 is TransantiagoAnnotation }
        mapView.removeAnnotations(transantiagoAnnotations)
    }
    
    private func centerMapAroundUserLocation(animated: Bool) {
        let initialCoordinate = userLocation
        let allowedSpan: CLLocationDegrees = 0.0025
        let initialRegion = MKCoordinateRegion(center: initialCoordinate, span: MKCoordinateSpan(latitudeDelta: allowedSpan, longitudeDelta: allowedSpan))
        mapView.setRegion(initialRegion, animated: animated)
    }
    
    private func placeAnnotations(aroundCoordinate coordinate: CLLocationCoordinate2D) {
        Transantiago.get.annotations(aroundCoordinate: coordinate) { (stops, bipSpots, metroStations) -> (Void) in
            guard let stops = stops, let bipSpots = bipSpots, let metroStations = metroStations else { return }
            mainThread {
                self.clearTransantiagoAnnotations(in: self.mapView)
                self.mapView.addAnnotations(stops)
                self.mapView.addAnnotations(bipSpots)
                self.mapView.addAnnotations(metroStations)
            }
        }
    }
    
    @IBAction func locationButtonTapped() {
        centerMapAroundUserLocation(animated: true)
    }

}
