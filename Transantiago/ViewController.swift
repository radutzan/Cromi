//
//  ViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/7/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import RaduKit
import MapKit
import StoreKit

class ViewController: ModalSupportingViewController, MKMapViewDelegate, LocationServicesDelegate, MapViewControllerDelegate, ServiceBarDelegate, InfoBannerDelegate {
    
    let locationServices = LocationServices()
    var mapController: MapViewController?
    
    @IBOutlet var buttonRow: ButtonRow!
    @IBOutlet var serviceBar: ServiceBar!
    @IBOutlet var infoBanner: InfoBanner!
    @IBOutlet var serviceBarHorizontalCenterConstraint: NSLayoutConstraint!
    @IBOutlet var infoBannerHorizontalCenterConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonRow.buttonItems = [ButtonItem(image: #imageLiteral(resourceName: "button bip"), title: "Bip button".localized(), action: bipButtonTapped(button:)),
                             ButtonItem(image: #imageLiteral(resourceName: "button location"), title: "Location button".localized(), action: locationButtonTapped(button:))]
//        buttonRow.setIsEnabled(on: [0], to: false)
        locationServices.delegate = self
        
        serviceBar.delegate = self
        serviceBar.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handle(serviceBarPan:))))
        serviceBarHorizontalCenterConstraint.constant = view.bounds.width
        
        infoBanner.delegate = self
        infoBanner.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handle(infoBannerPan:))))
        infoBannerHorizontalCenterConstraint.constant = view.bounds.width
        infoBanner.title = "Info Banner title".localized()
        infoBanner.message = "Info Banner message".localized()
        
        if let mapViewController = childViewControllers.first as? MapViewController {
            mapController = mapViewController
            mapController?.locationServices = locationServices
            mapController?.delegate = self
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let launchCount = UserDefaults.standard.integer(forKey: "launchCount") + 1
        UserDefaults.standard.set(launchCount, forKey: "launchCount")
        
        let nagKey = "didNag0.7"
        guard launchCount > 9, !UserDefaults.standard.bool(forKey: nagKey) else { return }
        SKStoreReviewController.requestReview()
        UserDefaults.standard.set(true, forKey: nagKey)
    }
    
    private let shouldPresentFeatureSpotlight = false
    private func presentFeatureSpotlightIfNeeded() {
        let spotlightKey = "Bip Cards Disabled"//"Bip Cards Spotlight"//"Live Buses Spotlight"//"Line View Spotlight"
        guard !UserDefaults.standard.bool(forKey: spotlightKey), shouldPresentFeatureSpotlight else { return }
        
        let spotlightAlert = UIAlertController(title: "Feature Spotlight alert title".localized(), message: "Feature Spotlight alert message".localized(), preferredStyle: .alert)
        spotlightAlert.addAction(UIAlertAction(title: "Feature Spotlight alert confirmation".localized(), style: .default, handler: nil))
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
        let stgoAlert = UIAlertController(title: "Not in Santiago alert title".localized(), message: "Not in Santiago alert message".localized(), preferredStyle: .alert)
        stgoAlert.addAction(UIAlertAction(title: "Not in Santiago alert confirmation".localized(), style: .default, handler: { (action) in
            self.locationServices.forceSantiago = true
            self.mapController?.centerMapAroundUserLocation(animated: true)
            self.mapController?.placeAnnotations(aroundCoordinate: self.locationServices.userLocation)
            self.presentFeatureSpotlightIfNeeded()
        }))
        present(stgoAlert, animated: true, completion: nil)
    }
    
    @objc private func locationButtonTapped(button: UIButton) {
        locationServices.updateLocation() {
            self.mapController?.centerMapAroundUserLocation(animated: true)
        }
    }
    
    @objc private func bipButtonTapped(button: UIButton) {
        button.isSelected = true
        let bipVC = BipViewController()
        bipVC.delegate = self
        bipVC.present(on: self) {
            button.isSelected = false
        }
        buttonRow.dismiss()
    }
    
    // MARK: - Modals
    override func modalWillPresent(modal: AbstractModalViewController) {
        super.modalWillPresent(modal: modal)
        mapController?.stopSignView.toggleStopPredictions(paused: true)
    }
    
    override func modalWillDismiss(modal: AbstractModalViewController) {
        super.modalWillDismiss(modal: modal)
        mapController?.stopSignView.toggleStopPredictions(paused: false)
        buttonRow.present()
    }
    
    // MARK: - Map interaction
    func signViewHeaderTapped(_ signView: SignView) {
        guard let signView = signView as? CromiSignView, let annotation = signView.annotation else { return }
        var coordinate = annotation.coordinate
        let spanMultiplier = signView.intrinsicContentSize.height / 580
        coordinate.latitude += Double(spanMultiplier) * 0.0014
        mapController?.centerMap(around: coordinate, animated: true)
    }
    
    func signDidSelect(service: Service) {
        guard let stopInfo = service.stopInfo else { return }
        mapController?.reset(holdForNextService: true, immediateServiceSwitch: storedCompleteServices[service.name] != nil)
        presentServiceBar(service: service)
        present(service: service, direction: stopInfo.direction)
        delay(0.42) {
            self.presentInfoBannerIfNeeded()
        }
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
            self.infoBannerRequestedDismissal()
        }
        mapController?.reset()
    }
    
    private func presentServiceBar(service: Service) {
        serviceBar.service = service
        guard serviceBarHorizontalCenterConstraint.constant != 0 else { return }
        UIView.animate(withDuration: 0.72, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: [], animations: {
            self.serviceBarHorizontalCenterConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private var storedCompleteServices: [String: Service] = [:]
    private var completePresentedService: Service?
    private func present(service: Service, direction: Service.Route.Direction) {
        var immediateServiceSwitch = false
        if let storedService = storedCompleteServices[service.name] {
            completePresentedService = storedService
            immediateServiceSwitch = true
        }
        if (completePresentedService == nil || completePresentedService?.routes == nil) && (service.routes != nil && service.routes!.count > 0) {
            completePresentedService = service
        }
        guard let completeService = completePresentedService, completeService.name == service.name, (completeService.routes ?? []).count > 0 else {
            SCLTransit.get.serviceRoutes(for: service) { (newService) in
                guard let newService = newService, let serviceRoutes = newService.routes, serviceRoutes.count > 0 else { return }
                mainThread {
                    print("got complete service \(newService.name)")
                    self.storedCompleteServices[newService.name] = newService
                    self.completePresentedService = newService
                    guard self.serviceBar.service != nil else { return }
                    self.present(service: newService, direction: direction)
                }
            }
            return
        }
        
        serviceBar.service = completeService
        serviceBar.selectedDirection = direction
        mapController?.reset(holdForNextService: true, immediateServiceSwitch: immediateServiceSwitch)
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
    
    // MARK: - Info banner
    private let liveBusesInfoBannerKey = "Did Present Live Buses Info Banner"
    private func presentInfoBannerIfNeeded(force: Bool = false) {
        guard !UserDefaults.standard.bool(forKey: liveBusesInfoBannerKey) else { return }
        UIView.animate(withDuration: 0.72, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: [], animations: {
            self.infoBannerHorizontalCenterConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func infoBannerRequestedDismissal() {
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.allowUserInteraction], animations: {
            self.infoBannerHorizontalCenterConstraint.constant = self.view.bounds.width
            self.view.layoutIfNeeded()
        }) { finished in
            UserDefaults.standard.set(true, forKey: self.liveBusesInfoBannerKey)
        }
    }
    
    private var initialInfoBannerBarConstant: CGFloat = 0
    @objc private func handle(infoBannerPan pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            initialInfoBannerBarConstant = infoBannerHorizontalCenterConstraint.constant
        case .changed:
            var proposedTranslation = pan.translation(in: self.view).x
            if proposedTranslation < 0 {
                proposedTranslation /= 4
            }
            infoBannerHorizontalCenterConstraint.constant = initialInfoBannerBarConstant + proposedTranslation
        default:
            if infoBannerHorizontalCenterConstraint.constant > 80 || pan.velocity(in: self.view).x > 820 {
                infoBannerRequestedDismissal()
            } else {
                presentInfoBannerIfNeeded(force: true)
            }
            return
        }
    }

}
