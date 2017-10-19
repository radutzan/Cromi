//
//  StreetSignView.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit

enum SignStyle {
    case dark, light
}

struct SignConstants {
    struct Color {
        static let bipBlue = UIColor(red: 0, green: 0.416, blue: 1, alpha: 1)
    }
    static let cornerRadius: CGFloat = 5
    static let secondarySubtitleOpacity: CGFloat = 0.55
}

class StreetSignView: NibLoadingView {

    var annotation: TransantiagoAnnotation? {
        didSet {
            reloadData()
        }
    }
    private var style: SignStyle = .dark {
        didSet {
            let backgroundColor = style == .dark ? UIColor.black : UIColor.white
            signView.backgroundColor = backgroundColor
            headerView.style = style
        }
    }
    
    @IBOutlet private var signView: UIView!
    @IBOutlet private var mainStackView: UIStackView!
    @IBOutlet private var headerView: SignHeaderView!
    private let maskerView = UIView()
    private var maskViewOriginSize = CGSize(width: 24, height: 24)
    private var maskViewCenter: CGPoint {
        return CGPoint(x: frame.width / 2, y: frame.height / 2)
    }
    
    private(set) var isVisible = false
    
    private let bipBlueColor = SignConstants.Color.bipBlue
    
    private var didPerformInitialSetup = false
    private func performInitialSetupIfNeeded() {
        if didPerformInitialSetup { return }
        alpha = 0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 17)
        layer.shadowRadius = 11
        layer.shadowOpacity = 0.2
        signView.layer.cornerRadius = SignConstants.cornerRadius
        signView.layer.masksToBounds = true
        signView.mask = maskerView
        maskerView.frame = CGRect(size: maskViewOriginSize, center: CGPoint.zero)
        maskerView.backgroundColor = .blue
        maskerView.layer.cornerRadius = 12
//        addSubview(maskerView) // masking debug
        didPerformInitialSetup = true
    }
    
    private func reloadData() {
        performInitialSetupIfNeeded()
        clearContentStack()
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.clear.cgColor
        mainStackView.spacing = 0
        
        headerView.annotation = annotation
        
        guard let annotation = annotation else { return }
        
        switch annotation {
        case let annotation as Stop:
            style = .dark
            
            var pendingServices: [Service] = []
            for service in annotation.services {
                pendingServices.append(service)
                
                if pendingServices.count == 2 || service == annotation.services.last! {
                    let serviceRowView = SignServiceRowView(services: pendingServices)
                    mainStackView.addArrangedSubview(serviceRowView)
                    mainStackView.layoutIfNeeded()
                    
                    for (index, service) in pendingServices.enumerated() {
                        serviceViews[service.name] = index == 0 ? serviceRowView.serviceView1 : serviceRowView.serviceView2
                    }
                    
                    pendingServices = []
                }
            }
            beginStopPredictions()
            
        case let annotation as BipSpot:
            style = .light
            let isBip = !(annotation is MetroStation)
            if isBip {
                signView.backgroundColor = bipBlueColor
                mainStackView.spacing = 5
            }
            
            guard annotation.operationHours.count > 0 else { return }
            let timetableView = SignTimetableView()
            for hours in annotation.operationHours {
                let hoursRow = SignHoursRowView()
                hoursRow.days = hours.rangeTitle
                hoursRow.hours = "\(hours.start) \(NSLocalizedString("to", comment: "")) \(hours.end)"
                if isBip { hoursRow.style = .dark }
                timetableView.add(hoursRow: hoursRow)
            }
            mainStackView.addArrangedSubview(timetableView)
            mainStackView.layoutIfNeeded()
            
        default:
            return
        }
        
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        view.frame.origin = CGPoint.zero
    }
    
    private func clearContentStack() {
        for view in mainStackView.arrangedSubviews {
            if view == headerView { continue }
            mainStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        mainStackView.layoutIfNeeded()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 220, height: signView.bounds.height)
    }
    
    func present(fromCenter originCenter: CGPoint, targetFrame: CGRect) {
        frame = CGRect(size: targetFrame.size, center: originCenter)
        let targetMaskSize = frame.insetBy(dx: -12, dy: -12).size
        maskerView.frame.size = maskViewOriginSize
        maskerView.center = maskViewCenter
        willAppear()
        
        UIView.animate(withDuration: 0.52, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
            self.alpha = 1
            self.frame = targetFrame
            self.maskerView.frame.size = targetMaskSize
            self.maskerView.center = self.maskViewCenter
        }, completion: nil)
    }
    
    func dismiss(toCenter targetCenter: CGPoint) {
        willDisappear()
        
        delay(1/60) {
            if self.isVisible { return }
            UIView.animateKeyframes(withDuration: 0.36, delay: 0, options: [.calculationModeCubic], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.7, animations: {
                    self.alpha = 0
                })
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    self.center = targetCenter
                    self.maskerView.frame.size = self.maskViewOriginSize
                    self.maskerView.center = self.maskViewCenter
                })
            }, completion: nil)
        }
    }
    
    private func willAppear() {
        isVisible = true
    }
    
    private func willDisappear() {
        isVisible = false
        endStopPredictions()
    }
    
    // MARK: - Stop predictions
    private var serviceViews: [String: SignServiceView] = [:]
    private var predictionUpdateTimer: Timer?
    
    private func beginStopPredictions() {
        getCurrentStopPrediction()
        startPredictionTimer()
    }
    
    private func endStopPredictions() {
        cancelPredictionTimer()
        serviceViews = [:]
    }
    
    @objc private func getCurrentStopPrediction() {
        guard let stop = annotation as? Stop else { return }
        CFAPI.get.prediction(forStopCode: stop.code) { (prediction) -> (Void) in
            guard let prediction = prediction else { return }
            for response in prediction.serviceResponses {
                guard let view = self.serviceViews[response.serviceName], let predictions = response.predictions else { continue }
                mainThread {
                    view.subtitle = predictions[0].predictionString
                    view.isSubtitleSecondary = false
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
}
