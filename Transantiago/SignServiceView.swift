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
            serviceLabel.textColor = isServiceSecondary ? UIColor(white: 1, alpha: SignConstants.secondarySubtitleOpacity) : serviceColor
        }
    }
    
    @IBOutlet private var serviceLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var subtitle2Label: UILabel!
    
    override func updateFonts() {
        serviceLabel.font = .serviceName
        subtitleLabel.font = .subtitle
        subtitle2Label.font = .subtitle
    }
    
    private func updateSubtitles() {
        
    }
}
