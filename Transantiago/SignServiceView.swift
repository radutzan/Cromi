//
//  SignServiceView.swift
//  Cromi
//
//  Created by Radu Dutzan on 4/10/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

@IBDesignable class SignServiceView: NibLoadingView {

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
            subtitle2Label.numberOfLines = subtitle == nil ? 2 : 1
        }
    }
    @IBInspectable var subtitle2: String? {
        didSet {
            subtitle2Label.text = subtitle2
        }
    }
    @IBInspectable var isServiceSecondary: Bool = false {
        didSet {
            serviceLabel.textColor = isServiceSecondary ? UIColor(white: 1, alpha: SignConstants.tertiaryOpacity) : serviceColor
            subtitle2Label.alpha = isServiceSecondary ? SignConstants.tertiaryOpacity : SignConstants.secondaryOpacity
        }
    }
    
    @IBOutlet private var serviceLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var subtitle2Label: UILabel!
    
    override func updateFonts() {
        serviceLabel.font = .serviceName
        subtitleLabel.font = .subtitle
        subtitleLabel.alpha = SignConstants.secondaryOpacity
        subtitle2Label.font = .subtitle
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
