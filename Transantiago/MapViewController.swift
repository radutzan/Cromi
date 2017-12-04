//
//  MapViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/2/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var mapView: MKMapView!
    var locationServices: LocationServices?
    
    private var selectedAnnotation: TransantiagoAnnotation?
    private let signView = StreetSignView()
    
    private let statusBarGradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        if #available(iOS 11.0, *) {
            mapView.mapType = .mutedStandard
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        statusBarGradientLayer.colors = [UIColor(red: 0.976, green: 0.961, blue: 0.929, alpha: 1).cgColor, UIColor(red: 0.976, green: 0.961, blue: 0.929, alpha: 0).cgColor]
        statusBarGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        statusBarGradientLayer.endPoint = CGPoint(x: 0, y: 1)
        view.layer.insertSublayer(statusBarGradientLayer, above: mapView.layer)
        
        view.addSubview(signView)
        
        let displayLink = CADisplayLink(target: self, selector: #selector(updateSignFrameIfNeeded))
        displayLink.add(to: .main, forMode: .defaultRunLoopMode)
    }
    
    override func viewWillLayoutSubviews() {
        statusBarGradientLayer.isHidden = UIApplication.shared.statusBarFrame.height <= 0
        if !statusBarGradientLayer.isHidden {
            statusBarGradientLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: view.bounds.width, height: 40))
        }
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
    // TODO: switch to layoutMargins?
    private let signProtectedInsets = UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
    private var protectedInsets: UIEdgeInsets {
        var systemInsets = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.height, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            systemInsets = view.safeAreaInsets
        }
        return UIEdgeInsets(top: signProtectedInsets.top + systemInsets.top, left: signProtectedInsets.left + systemInsets.left, bottom: signProtectedInsets.bottom + systemInsets.bottom, right: signProtectedInsets.right + systemInsets.right)
    }
    private var targetSignSize: CGSize {
        let maxHeight = view.bounds.height - protectedInsets.top - protectedInsets.bottom
        return CGSize(width: signView.intrinsicContentSize.width, height: signView.intrinsicContentSize.height > maxHeight ? maxHeight : signView.intrinsicContentSize.height)
    }
    private let signDistance: CGFloat = 25
    
    @objc private func updateSignFrameIfNeeded() {
        guard let selectedAnnotation = selectedAnnotation else { return }
        signView.frame = signFrame(forAnnotation: selectedAnnotation)
    }
    
    private func signFrame(forAnnotation annotation: MKAnnotation) -> CGRect {
        let annotationPoint = point(forAnnotation: annotation)
        
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
            proposedFrame.origin.y = view.bounds.height - protectedInsets.bottom - proposedFrame.height
        }
        
        return proposedFrame
    }
    
    private func point(forAnnotation annotation: MKAnnotation) -> CGPoint {
        return mapView.convert(annotation.coordinate, toPointTo: view).rounded()
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
    func centerMap(around coordinate: CLLocationCoordinate2D, animated: Bool) {
        let allowedSpan: CLLocationDegrees = 0.0025
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: allowedSpan, longitudeDelta: allowedSpan))
        mapView.setRegion(region, animated: animated)
    }
    
    func centerMapAroundUserLocation(animated: Bool) {
        guard let locationServices = locationServices else { return }
        centerMap(around: locationServices.userLocation, animated: animated)
    }
    
    func placeAnnotations(aroundCoordinate coordinate: CLLocationCoordinate2D, completion: (() -> ())? = nil) {
        TransantiagoAPI.get.annotations(aroundCoordinate: coordinate) { (stops, bipSpots, metroStations) in
            guard let stops = stops, let bipSpots = bipSpots, let metroStations = metroStations else { return }
            mainThread {
                let currentAnnotationsSet = Set(self.mapView.annotations.filter { $0 is TransantiagoAnnotation } as! [TransantiagoAnnotation])
                let newAnnotationsSet = Set((stops as [TransantiagoAnnotation]) + (bipSpots as [TransantiagoAnnotation]) + (metroStations as [TransantiagoAnnotation]))
                let annotationsToRemove = Array(currentAnnotationsSet.subtracting(newAnnotationsSet))
                let annotationsToAdd = Array(newAnnotationsSet.subtracting(currentAnnotationsSet))
                
                self.mapView.removeAnnotations(annotationsToRemove)
                self.mapView.addAnnotations(annotationsToAdd)
                
                completion?()
            }
        }
    }

    func selectNearestStop() {
        guard let locationServices = locationServices else { return }
        let stops = mapView.annotations.filter { $0 is Stop } as! [Stop]
        guard stops.count > 0 else { return }
        let currentLocation = CLLocation(latitude: locationServices.userLocation.latitude, longitude: locationServices.userLocation.longitude)
        var stopsByDistance: [CLLocationDistance: Stop] = [:]
        
        for stop in stops {
            let location = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
            let distance = location.distance(from: currentLocation)
            stopsByDistance[distance] = stop
        }
        
        let nearestDistance = stopsByDistance.keys.sorted()[0]
        guard let nearestStop = stopsByDistance[nearestDistance] else { return }
        mapView.selectAnnotation(nearestStop, animated: true)
    }

}