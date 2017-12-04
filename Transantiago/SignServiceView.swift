//
//  SignServiceView.swift
//  Cromi
//
//  Created by Radu Dutzan on 4/10/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

protocol SignServiceViewDelegate: AnyObject {
    func signDidSelect(service: Service)
}

@IBDesignable class SignServiceView: NibLoadingView {
    weak var delegate: SignServiceViewDelegate?

    private(set) var service: Service? = nil
    
    @IBInspectable var serviceName: String? {
        didSet {
            serviceLabel.text = serviceName
        }
    }
    @IBInspectable var serviceColor: UIColor? {
        didSet {
            serviceLabel.textColor = serviceColor
        }
    }
    @IBInspectable var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle ?? " "
            subtitleLabel.isHidden = subtitle == nil
        }
    }
    var isSelected: Bool = false {
        didSet {
            view.layer.backgroundColor = isSelected ? UIColor(white: 1, alpha: 0.15).cgColor : nil
            view.layer.cornerRadius = 2
        }
    }
    
    @IBOutlet private var serviceLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    
    override func updateFonts() {
        serviceLabel.font = .serviceName
        subtitleLabel.font = .subtitle
        subtitleLabel.alpha = SignConstants.secondaryOpacity
    }
    
    func populate(with service: Service) {
        self.service = service
        serviceName = service.name
        serviceColor = service.color
        subtitle = "\(NSLocalizedString("to", comment: "")) \(service.stopInfo?.headsign ?? "")"
    }
    
    func update(withResponse response: StopPrediction.ServiceResponse?) {
        var attrString = NSAttributedString()
        var isSecondary = true
        var shouldUpdateText = false
        
        defer {
            UIView.animate(withDuration: 0.24, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
                self.subtitleLabel.alpha = isSecondary ? SignConstants.tertiaryOpacity : 1
                if shouldUpdateText {
                    self.subtitleLabel.text = attrString.string
                    self.subtitleLabel.attributedText = attrString
                }
            }, completion: nil)
        }
        
        guard let response = response else {
            return
        }
        
        guard let predictions = response.predictions else {
            shouldUpdateText = true
            switch response.kind {
            case .noIncomingBuses:
                attrString = NSAttributedString(string: NSLocalizedString("No incoming buses", comment: ""))
            case .outOfSchedule:
                attrString = NSAttributedString(string: NSLocalizedString("Out of schedule", comment: ""))
            default:
                shouldUpdateText = false
            }
            return
        }
        
        isSecondary = false
        shouldUpdateText = true
        attrString = attributedString(fromPredictions: predictions)
    }
    
    @IBAction func buttonTapped() {
        guard let service = service else { return }
        delegate?.signDidSelect(service: service)
        isSelected = true
    }
    
    private func distanceString(from value: Int) -> String {
        var distance = Double(value)
        var isKilometers = false
        if distance >= 1000 {
            isKilometers = true
            distance = distance / 1000
        }
        let distanceStringValue = String(format: "%.\(isKilometers ? 1 : 0)f", distance)
        return "\(distanceStringValue) \(isKilometers ? "km" : "m")"
    }
    
    private func attributedString(fromPredictions predictions: [StopPrediction.ServiceResponse.Prediction]) -> NSAttributedString {
        let attrString = NSMutableAttributedString()
        for (index, prediction) in predictions.enumerated() {
            if index > 0 {
                attrString.append(NSAttributedString(string: "\n"))
            }
            let distance = Cromi.attributedString(from: distanceString(from: prediction.distance), style: .subtitle, textColor: .white)
            let time = Cromi.attributedString(from: " \(prediction.predictionString)", style: .subtitle, textColor: UIColor(white: 1, alpha: SignConstants.secondaryOpacity))
            attrString.append(distance)
            attrString.append(time)
        }
        return attrString
    }
}
