//
//  MapViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/2/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import RaduKit
import MapKit

protocol MapViewControllerDelegate: StopSignViewDelegate {}

class MapViewController: UIViewController, MKMapViewDelegate {
    weak var delegate: MapViewControllerDelegate? {
        didSet {
            stopSignView.delegate = delegate
            stopSignView.stopSignDelegate = delegate
            bipSignView.delegate = delegate
        }
    }
    
    enum Mode {
        case normal, lineView
    }
    private(set) var mode: Mode = .normal
    
    @IBOutlet var mapView: MKMapView!
    private let statusBarGradientLayer = CAGradientLayer()
    
    private let signViewController = SignViewController()
    let stopSignView = StopSignView()
    private let bipSignView = BipSignView()
    
    private let stopPinReuseIdentifier = "Stop pin"
    private var selectedAnnotation: TransantiagoAnnotation? {
        didSet {
            guard selectedAnnotation != oldValue else { return }
            updateSignOriginRectIfNeeded()
        }
    }
    
    private struct LineViewInfo {
        var presentedService: Service
        var currentDirection: Service.Route.Direction
    }
    private var lineViewInfo: LineViewInfo?
    
    var locationServices: LocationServices?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        if #available(iOS 11.0, *) {
            mapView.mapType = .mutedStandard
        }
        if #available(iOS 11.0, *) {
            mapView.register(StopAnnotationView.self, forAnnotationViewWithReuseIdentifier: stopPinReuseIdentifier)
        }
        
        if #available(iOS 11.0, *) {
            additionalSafeAreaInsets.bottom = 70
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        statusBarGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        statusBarGradientLayer.endPoint = CGPoint(x: 0, y: 1)
        view.layer.insertSublayer(statusBarGradientLayer, above: mapView.layer)
        
        signViewController.layoutInsets = UIEdgeInsets(top: 0, left: 8, bottom: 64, right: 8)
        addChildViewController(signViewController)
        view.addSubview(signViewController.view)
        signViewController.view.generateConstraintsToFillSuperview()
        
        let displayLink = CADisplayLink(target: self, selector: #selector(updateSignOriginRectIfNeeded))
        displayLink.add(to: .main, forMode: .defaultRunLoopMode)
    }
    
    override func viewWillLayoutSubviews() {
        statusBarGradientLayer.isHidden = UIApplication.shared.statusBarFrame.height <= 0
        if !statusBarGradientLayer.isHidden {
            statusBarGradientLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: view.bounds.width, height: 40))
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let darkColors = [UIColor(red: 0.167, green: 0.177, blue: 0.185, alpha: 1.00).cgColor, UIColor(red: 0.167, green: 0.177, blue: 0.185, alpha: 0).cgColor]
        let lightColors = [UIColor(red: 0.976, green: 0.961, blue: 0.929, alpha: 1).cgColor, UIColor(red: 0.976, green: 0.961, blue: 0.929, alpha: 0).cgColor]
        
        if #available(iOS 12.0, *) {
            statusBarGradientLayer.colors = traitCollection.userInterfaceStyle == .dark ? darkColors : lightColors
        } else {
            statusBarGradientLayer.colors = lightColors
        }
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if mode == .lineView { updateAnnotationViews() }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if mode == .lineView { updateAnnotationViews() }
        placeAnnotations(aroundCoordinate: mapView.centerCoordinate) {
            if self.mode == .lineView { self.updateAnnotationViews() }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? TransantiagoAnnotation else { return }
        selectedAnnotation = annotation
        
        if !(annotation is Stop) { view.image = pinImage(forAnnotation: annotation, selected: true) }
        if view.transform != .identity { view.transform = .identity }
        
        switch annotation {
        case let annotation as Stop:
            stopSignView.annotation = annotation
            signViewController.signView = stopSignView
            updateStopSignViewServiceSelection()
        case let annotation as BipSpot:
            bipSignView.annotation = annotation
            signViewController.signView = bipSignView
        default:
            signViewController.signView = nil
        }
        
        updateSignOriginRectIfNeeded()
        signViewController.originCornerRadius = annotation is Stop ? 2 : 12
        signViewController.showSign()
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let oldAnnotation = view.annotation as? TransantiagoAnnotation else { return }
        
        UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
            if !(oldAnnotation is Stop) { view.image = self.pinImage(forAnnotation: oldAnnotation, selected: false) }
            if self.mode == .lineView {
                self.process(annotationView: view, annotation: oldAnnotation)
            }
        }, completion: nil)
        
        selectedAnnotation = nil
        
        signViewController.hideSign()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let bus = annotation as? Bus {
            let reuseIdentifier = "Bus pin"
            let busView = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? BusAnnotationView) ?? BusAnnotationView(annotation: bus, reuseIdentifier: reuseIdentifier)
            busView.bus = bus
            busView.color = lineViewInfo?.presentedService.color ?? .black
            if #available(iOS 11.0, *) {
                busView.displayPriority = .required
                busView.collisionMode = .circle
            }
            busView.layer.zPosition = 1000
            process(annotationView: busView, annotation: annotation)
            return busView
        }
        
        guard let annotation = annotation as? TransantiagoAnnotation else { return nil }
        
        var reuseIdentifier = ""
        switch annotation {
        case let stop as Stop:
            let annotationView = (mapView.dequeueReusableAnnotationView(withIdentifier: stopPinReuseIdentifier) as? StopAnnotationView) ?? StopAnnotationView(annotation: annotation, reuseIdentifier: stopPinReuseIdentifier)
            annotationView.canShowCallout = false
            setStyle(for: annotationView, with: stop)
            if #available(iOS 11.0, *) {
                annotationView.displayPriority = .required
                annotationView.collisionMode = .rectangle
            }
            process(annotationView: annotationView, annotation: annotation)
            annotationView.layer.zPosition = 90
            return annotationView
            
        case is MetroStation:
            reuseIdentifier = "Metro pin"
        case is BipSpot:
            reuseIdentifier = "Bip pin"
        default:
            return nil
        }
        
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        annotationView.canShowCallout = false
        annotationView.image = pinImage(forAnnotation: annotation, selected: false)
        if #available(iOS 11.0, *) {
            annotationView.displayPriority = .required
            annotationView.collisionMode = .circle
        }
        process(annotationView: annotationView, annotation: annotation)
        annotationView.layer.zPosition = 10
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if mode == .lineView { updateAnnotationViews() }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let polylineRenderer = MKPolylineRenderer(polyline: polyline)
            polylineRenderer.lineWidth = 6
            polylineRenderer.lineJoin = .round
            polylineRenderer.lineCap = .round
            polylineRenderer.strokeColor = lineViewInfo?.presentedService.color.withAlphaComponent(0.5) ?? .black
            return polylineRenderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        mapView.userLocation.title = nil
    }
    
    // MARK: - Signs
    @objc private func updateSignOriginRectIfNeeded() {
        guard let selectedAnnotation = selectedAnnotation else { return }
        let width = selectedAnnotation is Stop ? 22 : 24
        let offsetY: CGFloat = selectedAnnotation is Stop ? -4 : -3
        signViewController.originRect = CGRect(size: CGSize(width: width, height: 24), center: point(forAnnotation: selectedAnnotation)).offsetBy(dx: 0, dy: offsetY)
    }
    
    private func updateStopSignViewServiceSelection() {
        if let stop = selectedAnnotation as? Stop, let lineViewInfo = lineViewInfo, mode == .lineView, stopContainsCurrentRoute(stop) {
            stopSignView.selectedService = lineViewInfo.presentedService
        } else {
            stopSignView.selectedService = nil
        }
    }
    
    // MARK: - Pins
    private func point(forAnnotation annotation: MKAnnotation) -> CGPoint {
        return mapView.convert(annotation.coordinate, toPointTo: nil)//.rounded()
    }
    
    private func pinImage(forAnnotation annotation: TransantiagoAnnotation, selected: Bool) -> UIImage? {
        var pinImage: UIImage?
        switch annotation {
        case is MetroStation:
            pinImage = selected ? #imageLiteral(resourceName: "pin metro selected") : #imageLiteral(resourceName: "pin metro")
        case is BipSpot:
            pinImage = selected ? #imageLiteral(resourceName: "pin bip selected") : #imageLiteral(resourceName: "pin bip")
        default:
            return nil
        }
        return pinImage
    }
    
    private func updateAnnotationViews() {
        for annotation in mapView.annotations {
            guard let annotationView = mapView.view(for: annotation) else { continue }
            process(annotationView: annotationView, annotation: annotation)
        }
    }
    
    private func process(annotationView view: MKAnnotationView, annotation: MKAnnotation) {
        let zLow: CGFloat = 10, zMid: CGFloat = 100, zHigh: CGFloat = 1000
        if (annotation is BipSpot || annotation is MetroStation) {
            view.transform = mode != .lineView ? .identity : CGAffineTransform(scaleX: lineViewNormalStopScale, y: lineViewNormalStopScale)
            view.layer.zPosition = zLow
        }
        if annotation is Bus {
            view.layer.zPosition = zHigh
        }
        if let stop = annotation as? Stop, let stopPin = view as? StopAnnotationView {
            setStyle(for: stopPin, with: stop)
            if mode == .lineView {
                if stopContainsCurrentRoute(stop) {
                    stopPin.layer.zPosition = zMid
                } else {
                    stopPin.layer.zPosition = zLow
                }
            }
        }
    }
    
    let lineViewNormalStopScale: CGFloat = 0.72
    private func setStyle(for annotationView: StopAnnotationView, with stop: Stop) {
        if let lineViewInfo = lineViewInfo, mode == .lineView {
            if stopContainsCurrentRoute(stop) {
                annotationView.superview?.bringSubview(toFront: annotationView)
            }
            annotationView.color = stopContainsCurrentRoute(stop) ? lineViewInfo.presentedService.color : nil
            annotationView.isInverted = !stopContainsCurrentRoute(stop)
            annotationView.transform = stopContainsCurrentRoute(stop) ? .identity : CGAffineTransform(scaleX: lineViewNormalStopScale, y: lineViewNormalStopScale)
        } else {
            annotationView.color = nil
            annotationView.isInverted = false
            annotationView.transform = .identity
        }
    }
    
    // MARK: - Helpers
    func centerMap(around coordinate: CLLocationCoordinate2D, animated: Bool, allowedSpan: CLLocationDegrees = 0.0025) {
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: allowedSpan, longitudeDelta: allowedSpan))
        mapView.setRegion(region, animated: animated)
    }
    
    func centerMapAroundUserLocation(animated: Bool) {
        guard let locationServices = locationServices else { return }
        centerMap(around: locationServices.userLocation, animated: animated)
    }
    
    func placeAnnotations(aroundCoordinate coordinate: CLLocationCoordinate2D, completion: (() -> ())? = nil) {
        SCLTransit.get.annotations(aroundCoordinate: coordinate) { (stops, bipSpots, metroStations) in
            guard let stops = stops, let bipSpots = bipSpots, let metroStations = metroStations else { return }
            mainThread {
                let currentAnnotationsSet = Set(self.mapView.annotations.filter { $0 is TransantiagoAnnotation } as! [TransantiagoAnnotation])
                let newAnnotationsSet = Set((stops as [TransantiagoAnnotation]) + (bipSpots as [TransantiagoAnnotation]) + (metroStations as [TransantiagoAnnotation]))
                var annotationsToRemove = Array(currentAnnotationsSet.subtracting(newAnnotationsSet))
                let annotationsToAdd = Array(newAnnotationsSet.subtracting(currentAnnotationsSet))
                
                if let selectedAnnotation = self.selectedAnnotation, let indexOfSelected = annotationsToRemove.index(of: selectedAnnotation) {
                    annotationsToRemove.remove(at: indexOfSelected)
                }
                
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
    
    func display(service: Service, direction: Service.Route.Direction) {
        guard let polyline = direction == .outbound ? service.outboundRoute?.polyline : service.inboundRoute?.polyline else { return }
        mode = .lineView
        lineViewInfo = LineViewInfo(presentedService: service, currentDirection: direction)
        mapView.add(polyline)
        startUpdatingLiveBuses()
        UIView.animate(withDuration: 0.24) {
            self.updateAnnotationViews()
        }
        updateStopSignViewServiceSelection()
        if mapView.region.span.latitudeDelta < 0.008 {
            centerMap(around: mapView.centerCoordinate, animated: true, allowedSpan: 0.0084)
        }
    }

    func reset(holdForNextService: Bool = false, immediateServiceSwitch: Bool = false) {
        mode = .normal
        lineViewInfo = nil
        if !immediateServiceSwitch {
            UIView.animate(withDuration: 0.24) {
                self.updateAnnotationViews()
            }
        }
        updateStopSignViewServiceSelection()
        stopUpdatingLiveBuses()
        for overlay in mapView.overlays {
            mapView.remove(overlay)
        }
        if !holdForNextService {
            centerMap(around: selectedAnnotation?.coordinate ?? mapView.centerCoordinate, animated: true, allowedSpan: 0.0042)
        }
    }
    
    private func stopContainsCurrentRoute(_ stop: Stop) -> Bool {
        if let lineViewInfo = lineViewInfo, mode == .lineView {
            let relevantStopCodes = lineViewInfo.currentDirection == .outbound ? lineViewInfo.presentedService.outboundRoute?.stopCodes : lineViewInfo.presentedService.inboundRoute?.stopCodes
            if let codes = relevantStopCodes, codes.contains(stop.code) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Live buses
    private var busAnnotations: [Bus] = []
    private var liveBusesUpdateTimer: Timer?
    
    private func startUpdatingLiveBuses() {
        guard mode == .lineView else { return }
        getCurrentLiveBuses()
        startLiveBusesTimer()
    }
    
    private func stopUpdatingLiveBuses() {
        cancelLiveBusesTimer()
        mapView.removeAnnotations(busAnnotations)
        busAnnotations = []
    }
    
    @objc private func getCurrentLiveBuses() {
        guard let lineViewInfo = lineViewInfo else { return }
        SCLTransit.get.buses(forService: lineViewInfo.presentedService.name, direction: lineViewInfo.currentDirection) { (buses) in
            guard let buses = buses else { return }
            mainThread {
                guard buses != self.busAnnotations else { return }
                self.mapView.removeAnnotations(self.busAnnotations)
                self.busAnnotations = buses
                self.mapView.addAnnotations(self.busAnnotations)
            }
        }
    }
    
    private func startLiveBusesTimer() {
        guard mode == .lineView else { return }
        cancelLiveBusesTimer()
        liveBusesUpdateTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(getCurrentLiveBuses), userInfo: nil, repeats: true)
    }
    
    private func cancelLiveBusesTimer() {
        liveBusesUpdateTimer?.invalidate()
        liveBusesUpdateTimer = nil
    }
}
