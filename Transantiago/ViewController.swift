//
//  ViewController.swift
//  Transantiago
//
//  Created by Radu Dutzan on 12/7/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit
import MapKit
import MessageUI

class ViewController: UIViewController, MKMapViewDelegate, MFMailComposeViewControllerDelegate, CLLocationManagerDelegate, TransantiagoAPIErrorDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var errorInfoButton: MapButton!
    
    private var selectedAnnotation: TransantiagoAnnotation?
    private var scrollEventTimer: Timer?
    private let signView = StreetSignView()
    private let gradientLayer = CAGradientLayer()
    
    private let locationManager = CLLocationManager()
    private var locationAuthorized = false {
        didSet {
            guard locationAuthorized, !didSetInitialLocation else { return }
            updateLocation() {
                self.centerMapAroundUserLocation(animated: false)
                self.placeAnnotations(aroundCoordinate: self.mapView.centerCoordinate) {
                    self.selectNearestStop()
                }
                self.didSetInitialLocation = true
            }
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
        
        Transantiago.get.errorDelegate = self
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 200
        locationManager.requestWhenInUseAuthorization()
        
        gradientLayer.colors = [UIColor(red: 0.976, green: 0.961, blue: 0.929, alpha: 1).cgColor, UIColor(red: 0.976, green: 0.961, blue: 0.929, alpha: 0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        view.layer.insertSublayer(gradientLayer, above: mapView.layer)
        
        view.insertSubview(signView, at: 1)//addSubview()
        
        let displayLink = CADisplayLink(target: self, selector: #selector(updateSignFrameIfNeeded))
        displayLink.add(to: .main, forMode: .defaultRunLoopMode)
    }
    
    override func viewWillLayoutSubviews() {
        gradientLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: view.bounds.width, height: 40))
    }
    
    // MARK: - CLLocationManagerDelegate
    private var needsLocationUpdate = false
    private var locationUpdateCompletionHandler: (() -> ())?
    func updateLocation(completion: (() -> ())? = nil) {
        guard locationAuthorized else { return }
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
                let stgoAlert = UIAlertController(title: NSLocalizedString("Not in Santiago alert title", comment: ""), message: NSLocalizedString("Not in Santiago alert message", comment: ""), preferredStyle: .alert)
                stgoAlert.addAction(UIAlertAction(title: NSLocalizedString("Not in Santiago alert confirmation", comment: ""), style: .default, handler: { (action) in
                    self.forceSantiago = true
                    self.centerMapAroundUserLocation(animated: true)
                    self.placeAnnotations(aroundCoordinate: self.userLocation)
                }))
                self.present(stgoAlert, animated: true, completion: nil)
            }
        }
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
        
        // TODO: make these insets more aware of environment
        let protectedInsets = UIEdgeInsets(top: 30, left: 10, bottom: 80, right: 10)
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
    
    // MARK: - Error reporting
    private var didPresentAPIErrorAlert = false
    private var failingAPIs: [Transantiago.APIType] = []
    
    func transantiagoFailingAPIsDidChange(_ apis: [Transantiago.APIType]) {
        failingAPIs = apis
        toggleErrorInfoButton(hidden: apis.count == 0)
        guard apis.count > 0, !didPresentAPIErrorAlert else { return }
        presentAPIErrorAlert()
        didPresentAPIErrorAlert = true
    }
    
    private func toggleErrorInfoButton(hidden: Bool) {
        mainThread {
            guard (hidden && self.errorInfoButton.alpha == 1) || (!hidden && self.errorInfoButton.alpha == 0) else { return }
            UIView.animate(withDuration: 0.24) {
                self.errorInfoButton.alpha = hidden ? 0 : 1
            }
        }
    }
    
    @IBAction func infoButtonPressed() {
        presentAPIErrorAlert()
    }
    
    private func presentAPIErrorAlert() {
        guard failingAPIs.count > 0 else { return }
        
        func apiLegibleString(forType type: Transantiago.APIType, forceSpanish: Bool = false) -> String {
            switch type {
            case .mapAnnotations:
                return forceSpanish ? "mapa" : "map"
            case .serviceInfo:
                return forceSpanish ? "información de recorrido" : "service information"
            case .stopPrediction:
                return forceSpanish ? "predicción de parada" : "stop prediction"
            }
        }
        
        func failingAPIsString(forceSpanish: Bool = false) -> String {
            var failingAPIsString = ""
            for (index, api) in failingAPIs.enumerated() {
                if index > 0 && index == failingAPIs.count - 1 { failingAPIsString += " \(forceSpanish ? "y" : NSLocalizedString("and", comment: "")) " }
                else if index > 0 { failingAPIsString += ", " }
                failingAPIsString += forceSpanish ? apiLegibleString(forType: api, forceSpanish: forceSpanish) : NSLocalizedString(apiLegibleString(forType: api), comment: "")
            }
            return failingAPIsString
        }
        
        
        let controller = UIAlertController(title: "\(NSLocalizedString("API Error title", comment: "")): \(failingAPIsString())", message: NSLocalizedString("API Error message", comment: ""), preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("Tweet @transantiago", comment: ""), style: .default, handler: { (action) in
            let tweetString = "@transantiago Quiero que @cromi_app vuelva a funcionar! Restauren APIs de \(failingAPIsString(forceSpanish: true)) por favor!"
            let baseURLStrings = ["twitter://post?message=","https://twitter.com/intent/tweet?text="]
            for urlString in baseURLStrings {
                guard let url = URL(string: "\(urlString)\(tweetString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)") else { continue }
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    break
                }
            }
        }))
        controller.addAction(UIAlertAction(title: NSLocalizedString("Email Transantiago", comment: ""), style: .default, handler: { (action) in
            if MFMailComposeViewController.canSendMail() {
                let mailComposer = MFMailComposeViewController()
                mailComposer.mailComposeDelegate = self
                mailComposer.setSubject("Arreglen sus APIs, por favor")
                mailComposer.setToRecipients(["contacto@transantiago.cl"])
                mailComposer.setMessageBody("Hola,\n\nLa app Cromi (https://itunes.apple.com/us/app/cromi/id1226025448?mt=8), que uso para ver los tiempos de llegada de los buses, dejó de funcionar porque sus APIs de \(failingAPIsString(forceSpanish: true)) están fallando. Por favor, restaúrenlas para poder seguir usando la aplicación. Gracias de antemano.\n\nAtentamente,", isHTML: false)
                self.present(mailComposer, animated: true, completion: nil)
            }
        }))
        controller.addAction(UIAlertAction(title: NSLocalizedString("Follow Cromi", comment: ""), style: .default, handler: { (action) in
            let urlStrings = ["twitter://user?screen_name=cromi_app","https://twitter.com/cromi_app"]
            for urlString in urlStrings {
                guard let url = URL(string: urlString) else { continue }
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    break
                }
            }
        }))
        controller.addAction(UIAlertAction(title: NSLocalizedString("Done", comment: ""), style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    private func centerMapAroundUserLocation(animated: Bool) {
        let allowedSpan: CLLocationDegrees = 0.0025
        let userRegion = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: allowedSpan, longitudeDelta: allowedSpan))
        mapView.setRegion(userRegion, animated: animated)
    }
    
    private func placeAnnotations(aroundCoordinate coordinate: CLLocationCoordinate2D, completion: (() -> ())? = nil) {
        Transantiago.get.annotations(aroundCoordinate: coordinate) { (stops, bipSpots, metroStations) in
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
    
    private func selectNearestStop() {
        let stops = mapView.annotations.filter { $0 is Stop } as! [Stop]
        guard stops.count > 0 else { return }
        let currentLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
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
    
    @IBAction func locationButtonTapped() {
        updateLocation() {
            self.centerMapAroundUserLocation(animated: true)
        }
    }

}
