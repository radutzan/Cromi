//
//  StreetSignView.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import RaduKit

protocol StopSignViewDelegate: SignServiceViewDelegate {
}

class StopSignView: SignView, SignServiceViewDelegate {
    weak var stopSignDelegate: StopSignViewDelegate?
    
    var annotation: Stop? {
        didSet {
            reloadData()
        }
    }
    var selectedService: Service? {
        didSet {
            for (serviceName, view) in serviceViews {
                view.isSelected = serviceName == selectedService?.name
            }
        }
    }
    private var signHeaderView = SignHeaderView()
    private var mainStackView = UIStackView()
    
    // MARK: - Setup
    override func didLoadNibView() {
        super.didLoadNibView()
        view.backgroundColor = .black
        
        headerView = signHeaderView
        signHeaderView.widthAnchor.constraint(equalToConstant: TypeStyle.proportionalContainerSize(for: 246, normalize: false)).isActive = true
        signHeaderView.heightAnchor.constraint(equalToConstant: TypeStyle.proportionalContainerSize(for: 56, normalize: true)).isActive = true
        signHeaderView.style = .dark
        
        contentView = mainStackView
        mainStackView.axis = .vertical
        mainStackView.alignment = .fill
        mainStackView.distribution = .fill
        mainStackView.spacing = 0
    }
    
    private func reloadData() {
        clearContentStack()
        
        defer {
            mainStackView.setNeedsLayout()
            setNeedsLayout()
            layoutIfNeeded()
        }
        
        signHeaderView.annotation = annotation
        
        guard let annotation = annotation else { return }
        
        var pendingServices: [Service] = []
        for service in annotation.services {
            pendingServices.append(service)
            
            if pendingServices.count == 2 || service == annotation.services.last! {
                let serviceRowView = SignServiceRowView(services: pendingServices)
                mainStackView.addArrangedSubview(serviceRowView)
                
                for (index, service) in pendingServices.enumerated() {
                    serviceViews[service.name] = index == 0 ? serviceRowView.serviceView1 : serviceRowView.serviceView2
                    serviceViews[service.name]?.delegate = self
                }
                
                pendingServices = []
            }
        }
        beginStopPredictions()
    }
    
    private func clearContentStack() {
        for view in mainStackView.arrangedSubviews {
            if view == headerView { continue }
            mainStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        mainStackView.setNeedsLayout()
    }
    
    // MARK: - Lifecycle
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
    private var serviceViews: [String: SignServiceView] = [:]
    private var predictionUpdateTimer: Timer?
    
    func beginStopPredictions() {
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
        guard let stop = annotation else { return }
        SCLTransit.get.prediction(forStopCode: stop.code) { (prediction) -> (Void) in
            guard let prediction = prediction else { return }
            for (service, view) in self.serviceViews {
                let responses = prediction.serviceResponses.filter { $0.serviceName.lowercased() == service.lowercased() }
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
