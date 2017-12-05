//
//  ServiceBar.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/2/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

protocol ServiceBarDelegate: AnyObject {
    func serviceBarSelected(direction: Service.Route.Direction, service: Service)
    func serviceBarRequestedDismissal()
}

class ServiceBar: NibLoadingView {
    
    weak var delegate: ServiceBarDelegate?
    
    @IBOutlet private var serviceNameLabel: UILabel!
    @IBOutlet private var directionButton1: UIButton!
    @IBOutlet private var directionButton2: UIButton!
    @IBOutlet private var buttonStackView: UIStackView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var closeButton: UIButton!

    var service: Service? {
        didSet {
            setUpBar()
        }
    }
    var selectedDirection: Service.Route.Direction = .outbound {
        didSet {
            directionButton1.isSelected = selectedDirection == .outbound
            directionButton2.isSelected = selectedDirection == .inbound
            updateSegmentedControl()
        }
    }
    
    private func setUpBar() {
        guard let service = service else { return }
        serviceNameLabel.text = service.name
        serviceNameLabel.textColor = service.color
        
        backgroundColor = .clear
        layer.backgroundColor = UIColor.white.cgColor
        layer.cornerRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 17)
        layer.shadowRadius = 11
        layer.shadowOpacity = 0.2
        
        defer {
            let hasRoutes = service.routes != nil
            UIView.animate(withDuration: 0.16) {
                self.activityIndicator.alpha = hasRoutes ? 0 : 1
                self.buttonStackView.alpha = hasRoutes ? 1 : 0
            }
        }
        guard let outboundRoute = service.outboundRoute, let inboundRoute = service.inboundRoute else {
            return
        }
        directionButton1.setTitle("\(NSLocalizedString("to", comment: "")) \(outboundRoute.headsign)", for: .normal)
        directionButton1.titleLabel?.numberOfLines = 2
        directionButton2.setTitle("\(NSLocalizedString("to", comment: "")) \(inboundRoute.headsign)", for: .normal)
        directionButton2.titleLabel?.numberOfLines = 2
        updateSegmentedControl()
    }
    
    private func updateSegmentedControl() {
        guard let service = service else { return }
        let buttons = [directionButton1!, directionButton2!]
        for button in buttons {
            if button.isSelected {
                button.backgroundColor = service.color
            } else {
                button.backgroundColor = .clear
            }
        }
    }
    
    @IBAction private func segmentedControlButtonTapped(button: UIButton) {
        guard let service = service else { return }
        selectedDirection = button == directionButton1 ? .outbound : .inbound
        delegate?.serviceBarSelected(direction: selectedDirection, service: service)
    }
    
    @IBAction private func closeButtonTapped() {
        delegate?.serviceBarRequestedDismissal()
    }

}
