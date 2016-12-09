//
//  ViewController.swift
//  Transantiago
//
//  Created by Radu Dutzan on 12/7/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var mapView: MKMapView!
    
    private var selectedAnnotation: TransantiagoAnnotation?
    private var scrollEventTimer: Timer?
    private let signView = StreetSignView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        view.addSubview(signView)
        
        // test/mock stuff
        let initialCoordinate = CLLocationCoordinate2DMake(-33.425567, -70.614486)
        let allowedSpan: CLLocationDegrees = 0.0025
        let initialRegion = MKCoordinateRegion(center: initialCoordinate, span: MKCoordinateSpan(latitudeDelta: allowedSpan, longitudeDelta: allowedSpan))
        mapView.setRegion(initialRegion, animated: false)
        
        Transantiago.get.annotations(aroundCoordinate: initialCoordinate) { (stops, bipSpots, metroStations) -> (Void) in
            guard let stops = stops, let bipSpots = bipSpots, let metroStations = metroStations else { return }
            mainThread {
                self.mapView.addAnnotations(stops)
                self.mapView.addAnnotations(bipSpots)
                self.mapView.addAnnotations(metroStations)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapViewDidScroll()
        scrollEventTimer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true, block: { (timer) in
            self.mapViewDidScroll()
        })
        RunLoop.main.add(scrollEventTimer!, forMode: .commonModes)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        scrollEventTimer?.invalidate()
        scrollEventTimer = nil
        print("region changed")
    }
    
    private func mapViewDidScroll() {
        if let selectedAnnotation = selectedAnnotation {
            signView.frame = signFrame(forAnnotation: selectedAnnotation)
        }
    }
    
    private let originSignSize = CGSize(width: 22, height: 24)
    private let targetSignSize = CGSize(width: 215, height: 142)
    private let signDistance: CGFloat = 20
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? TransantiagoAnnotation else { return }
        selectedAnnotation = annotation
        
        signView.frame = CGRect(size: originSignSize, center: point(forAnnotation: selectedAnnotation!))
        signView.annotation = annotation
        
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.signView.alpha = 1
            self.signView.frame = self.signFrame(forAnnotation: self.selectedAnnotation!)
        }, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        let oldAnnotation: MKAnnotation! = selectedAnnotation
        selectedAnnotation = nil
        
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.signView.alpha = 0
            self.signView.frame = CGRect(size: self.originSignSize, center: self.point(forAnnotation: oldAnnotation))
        }) { (finished) in
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is TransantiagoAnnotation else { return nil }
        
        var reuseIdentifier = ""
        var pinImage: UIImage?
        switch annotation {
        case is Stop:
            reuseIdentifier = "Stop pin"
            pinImage = #imageLiteral(resourceName: "pin paradero")
        case is MetroStation:
            reuseIdentifier = "Metro pin"
            pinImage = #imageLiteral(resourceName: "pin metro")
        case is BipSpot:
            reuseIdentifier = "Bip pin"
            pinImage = #imageLiteral(resourceName: "pin bip")
        default:
            return nil
        }
        
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        annotationView.canShowCallout = false
        annotationView.image = pinImage
        
        return annotationView
    }

}
