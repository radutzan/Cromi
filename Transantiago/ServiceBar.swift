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
        guard let serviceRoutes = service.routes else {
            return
        }
        directionButton1.setTitle("\(NSLocalizedString("to", comment: "")) \(serviceRoutes[0].headsign)", for: .normal)
        directionButton1.titleLabel?.numberOfLines = 2
        directionButton2.setTitle("\(NSLocalizedString("to", comment: "")) \(serviceRoutes[1].headsign)", for: .normal)
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
        button.isSelected = true
        directionButton1.isSelected = button == directionButton1
        directionButton2.isSelected = button == directionButton2
        updateSegmentedControl()
        delegate?.serviceBarSelected(direction: button == directionButton1 ? .outbound : .inbound, service: service)
    }
    
    @IBAction private func closeButtonTapped() {
        delegate?.serviceBarRequestedDismissal()
    }

}
