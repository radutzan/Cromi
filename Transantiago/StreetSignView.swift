//
//  StreetSignView.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit

protocol StreetSignViewDelegate: SignServiceViewDelegate {
    func signDidTapHeader(_ signView: StreetSignView)
}

enum SignStyle {
    case dark, light
}

struct SignConstants {
    struct Color {
        static let bipBlue = UIColor(red: 0, green: 0.416, blue: 1, alpha: 1)
    }
    static let cornerRadius: CGFloat = 8
    static let secondaryOpacity: CGFloat = 0.64
    static let tertiaryOpacity: CGFloat = 0.36
}

class StreetSignView: NibLoadingView, SignServiceViewDelegate {
    weak var delegate: StreetSignViewDelegate?
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
    var selectedService: Service? {
        didSet {
            for (serviceName, view) in serviceViews {
                view.isSelected = serviceName == selectedService?.name
            }
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
    
    // MARK: - Setup
    override func didLoadNibView() {
        alpha = 0
//        isUserInteractionEnabled = false
        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOffset = CGSize(width: 0, height: 17)
//        layer.shadowRadius = 11
        layer.shadowOffset = CGSize(width: 0, height: 14.5)
        layer.shadowRadius = 9
        layer.shadowOpacity = 0.2
        signView.layer.cornerRadius = SignConstants.cornerRadius
        signView.layer.masksToBounds = true
        signView.mask = maskerView
        maskerView.frame = CGRect(size: maskViewOriginSize, center: CGPoint.zero)
        maskerView.backgroundColor = .blue
        maskerView.layer.cornerRadius = 12
//        addSubview(maskerView) // masking debug
        headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handle(headerViewTap:))))
    }
    
    private func reloadData() {
        clearContentStack()
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.clear.cgColor
        mainStackView.spacing = 0
        
        defer {
            mainStackView.layoutIfNeeded()
            signView.setNeedsLayout()
            signView.layoutIfNeeded()
            setNeedsLayout()
            layoutIfNeeded()
        }
        
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
                    mainStackView.setNeedsLayout()
                    
                    for (index, service) in pendingServices.enumerated() {
                        serviceViews[service.name] = index == 0 ? serviceRowView.serviceView1 : serviceRowView.serviceView2
                        serviceViews[service.name]?.delegate = self
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
            mainStackView.setNeedsLayout()
            
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
            mainStackView.setNeedsLayout()
            
        default:
            return
        }
    }
    
    
    // TouchTransparentView
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Layout
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
        let width = min(TypeStyle.proportionalContainerSize(for: 246, normalize: false), UIScreen.main.bounds.width - 16)
        return CGSize(width: width, height: signView.bounds.height)
    }
    
    // MARK: - Actions
    func signDidSelect(service: Service) {
        selectedService = service
        delegate?.signDidSelect(service: service)
    }
    
    @objc private func handle(headerViewTap: UITapGestureRecognizer) {
        delegate?.signDidTapHeader(self)
    }
    
    // MARK: - Lifecycle
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
//        isHidden = false
        isUserInteractionEnabled = true
    }
    
    private func willDisappear() {
        isVisible = false
        isUserInteractionEnabled = false
        endStopPredictions()
    }
    
    private func didDisappear() {
        isHidden = true
    }
    
    // MARK: - Stop predictions
    private var serviceViews: [String: SignServiceView] = [:]
    private var predictionUpdateTimer: Timer?
    
    private func beginStopPredictions() {
        guard annotation is Stop else { return }
        getCurrentStopPrediction()
        startPredictionTimer()
        addRefreshIndicator()
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
                let responses = prediction.serviceResponses.filter { $0.serviceName.lowercased() == service.lowercased() }
                mainThread {
                    view.update(withResponse: responses.count > 0 ? responses[0] : nil)
                }
            }
        }
    }
    
    private func startPredictionTimer() {
        guard annotation is Stop else { return }
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
        refreshIndicator.frame.origin = CGPoint(x: intrinsicContentSize.width - indicatorSize - indicatorDistance, y: indicatorDistance)
        refreshIndicator.backgroundColor = .white
        refreshIndicator.alpha = 0
        refreshIndicator.layer.cornerRadius = indicatorSize / 2
        addSubview(refreshIndicator)
        UIView.animateKeyframes(withDuration: 1.0, delay: 0, options: [.autoreverse, .repeat], animations: {
            self.refreshIndicator.alpha = 0.75
        }, completion: nil)
    }
    
    private func removeRefreshIndicator() {
        refreshIndicator.removeFromSuperview()
    }
}
