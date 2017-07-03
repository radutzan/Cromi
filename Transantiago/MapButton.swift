//
//  MapButton.swift
//  Cromi
//
//  Created by Radu Dutzan on 7/2/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

class MapButton: UIButton {

    override func willMove(toSuperview newSuperview: UIView?) {
        setUpButtonIfNeeded()
    }
    
    private var didSetUpButton = false
    private func setUpButtonIfNeeded() {
        guard !didSetUpButton else { return }
        layer.backgroundColor = UIColor.white.cgColor
        layer.cornerRadius = bounds.width / 2
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.2
        didSetUpButton = true
    }

}
