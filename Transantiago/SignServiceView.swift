//
//  SignServiceView.swift
//  Transantiago
//
//  Created by Radu Dutzan on 4/10/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

class SignServiceView: NibLoadingView {

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
            subtitleLabel.text = subtitle
        }
    }
    @IBInspectable var isSubtitleSecondary: Bool = false {
        didSet {
            subtitleLabel.alpha = isSubtitleSecondary ? SignConstants.secondarySubtitleOpacity : 1
        }
    }
    
    @IBOutlet private var serviceLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!

}
