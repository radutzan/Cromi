//
//  MapButton.swift
//  Cromi
//
//  Created by Radu Dutzan on 7/2/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

class FloatingButton: UIButton {

    override func willMove(toSuperview newSuperview: UIView?) {
        setUpButtonIfNeeded()
    }
    
    private var didSetUpButton = false
    private func setUpButtonIfNeeded() {
        guard !didSetUpButton else { return }
        clipsToBounds = false
        backgroundColor = .clear
        let size: CGFloat = 44 // 😒
        layer.backgroundColor = UIColor.white.cgColor
        layer.cornerRadius = size / 2
        layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size), cornerRadius: layer.cornerRadius).cgPath
        apply(shadow: Shadow.floatingHigh)
        didSetUpButton = true
    }

}
