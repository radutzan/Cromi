//
//  SignHoursRowView.swift
//  Cromi
//
//  Created by Radu Dutzan on 4/10/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import RaduKit

class SignHoursRowView: NibLoadingView {

    @IBInspectable var days: String? {
        didSet {
            daysLabel.text = days
        }
    }
    @IBInspectable var hours: String? {
        didSet {
            hoursLabel.text = hours
        }
    }
    var style: CromiSignStyle = .dark {
        didSet {
            let textColor = style == .dark ? UIColor.white : UIColor.black
            daysLabel.textColor = textColor
            hoursLabel.textColor = textColor
        }
    }
    
    @IBOutlet private var daysLabel: UILabel!
    @IBOutlet private var hoursLabel: UILabel!
    
    override func willMove(toSuperview newSuperview: UIView?) {
        daysLabel.font = .subtitle
        hoursLabel.font = .subtitle
    }

}
