//
//  StreetSignView.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import RaduKit

protocol StopSignViewDelegate: SignServiceViewDelegate, SignViewDelegate {
}

class StopSignView: CromiSignView, SignServiceViewDelegate {
    weak var stopSignDelegate: StopSignViewDelegate?
    
    private var serviceViews: [Service: SignServiceView] = [:]
    
    var selectedService: Service? {
        didSet {
            for (service, view) in serviceViews {
                view.isSelected = service == selectedService
            }
        }
    }
    
    // MARK: - Setup
    override func didLoadNibView() {
        super.didLoadNibView()
        view.backgroundColor = .black
    }
    
    override func reloadData() {
        super.reloadData()
        guard let annotation = annotation as? Stop else { return }
        var finalServices = annotation.services
        
        // dedupe services
        var previousService: Service?
        var indicesToRemove: [Int] = []
        for (index, service) in annotation.services.enumerated() {
            if service.name == previousService?.name {
                indicesToRemove.append(index)
            }
            previousService = service
        }
        for index in indicesToRemove.reversed() {
            finalServices.remove(at: index)
        }
        
        // build views
        var pendingServices: [Service] = []
        for service in finalServices {
            pendingServices.append(service)
            
            if pendingServices.count == 2 || service == finalServices.last! {
                let serviceRowView = SignServiceRowView(services: pendingServices)
                mainStackView.addArrangedSubview(serviceRowView)
                
                for (index, service) in pendingServices.enumerated() {
                    serviceViews[service] = index == 0 ? serviceRowView.serviceView1 : serviceRowView.serviceView2
                    serviceViews[service]?.delegate = self
                }
                
                pendingServices = []
            }
        }
    }
    
    // MARK: - Lifecycle
    override func willAppear() {
        super.willAppear()
        beginStopPredictions()
    }
    
    override func willDisappear() {
        super.willDisappear()
        endStopPredictions()
    }
    
    // MARK: - Actions
    func signDidSelect(service: Service) {
        selectedService = service
        stopSignDelegate?.signDidSelect(service: service)
    }
    
    // MARK: - Stop predictions
    private var predictionUpdateTimer: Timer?
    
    func toggleStopPredictions(paused: Bool) {
        if paused {
            pauseStopPredictions()
        } else {
            beginStopPredictions()
        }
    }
    
    func beginStopPredictions() {
        guard isVisible else { return }
        getCurrentStopPrediction()
        startPredictionTimer()
        addRefreshIndicator()
    }
    
    func pauseStopPredictions() {
        cancelPredictionTimer()
    }
    
    private func endStopPredictions() {
        cancelPredictionTimer()
        serviceViews = [:]
        removeRefreshIndicator()
    }
    
    @objc private func getCurrentStopPrediction() {
        guard let stop = annotation as? Stop else { return }
        SCLTransit.get.prediction(forStopCode: stop.code) { (prediction) -> (Void) in
            guard let prediction = prediction else { return }
            for (service, view) in self.serviceViews {
                let responses = prediction.serviceResponses.filter { $0.serviceName.lowercased() == service.name.lowercased() }
                mainThread {
                    view.update(withResponse: responses.count > 0 ? responses[0] : nil)
                }
            }
        }
    }
    
    private func startPredictionTimer() {
        cancelPredictionTimer()
        predictionUpdateTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(getCurrentStopPrediction), userInfo: nil, repeats: true)
    }

    private func cancelPredictionTimer() {
        predictionUpdateTimer?.invalidate()
        predictionUpdateTimer = nil
    }
    
    private let refreshIndicator = UIView()
    private func addRefreshIndicator() {
        let indicatorSize: CGFloat = 5
        let indicatorDistance: CGFloat = 10
        refreshIndicator.frame.size = CGSize(width: indicatorSize, height: indicatorSize)
        refreshIndicator.frame.origin = CGPoint(x: signHeaderView.bounds.width - indicatorSize - indicatorDistance, y: indicatorDistance)
        refreshIndicator.backgroundColor = .white
        refreshIndicator.alpha = 0
        refreshIndicator.layer.cornerRadius = indicatorSize / 2
        signHeaderView.addSubview(refreshIndicator)
        UIView.animateKeyframes(withDuration: 1.0, delay: 0, options: [.autoreverse, .repeat], animations: {
            self.refreshIndicator.alpha = 0.75
        }, completion: nil)
    }
    
    private func removeRefreshIndicator() {
        refreshIndicator.removeFromSuperview()
    }
}
