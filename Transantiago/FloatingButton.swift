//
//  MapButton.swift
//  Cromi
//
//  Created by Radu Dutzan on 7/2/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

class FloatingButton: UIButton {
    var size: CGFloat = 44
    var shadow = Shadow.floatingHigh

    override func willMove(toSuperview newSuperview: UIView?) {
        setUpButtonIfNeeded()
    }
    
    private var didSetUpButton = false
    private func setUpButtonIfNeeded() {
        guard !didSetUpButton else { return }
        clipsToBounds = false
        backgroundColor = .clear
        layer.backgroundColor = UIColor.white.cgColor
        layer.cornerRadius = size / 2
        layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size), cornerRadius: layer.cornerRadius).cgPath
        apply(shadow: shadow)
        didSetUpButton = true
    }

}
