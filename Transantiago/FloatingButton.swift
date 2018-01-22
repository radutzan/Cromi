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
    private var selectedScale: CGFloat = 1.32
    
    override func setImage(_ image: UIImage?, for state: UIControlState) {
        super.setImage(image?.withRenderingMode(.alwaysTemplate), for: state)
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        setUpButtonIfNeeded()
    }
    
    private var didSetUpButton = false
    private func setUpButtonIfNeeded() {
        guard !didSetUpButton else { return }
        clipsToBounds = false
        backgroundColor = .clear
        adjustsImageWhenHighlighted = false
        layer.backgroundColor = UIColor.white.cgColor
        layer.cornerRadius = size / 2
        layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size), cornerRadius: layer.cornerRadius).cgPath
        apply(shadow: shadow)
        didSetUpButton = true
    }
    
    override var tintColor: UIColor! {
        didSet {
            guard tintColor != .white else { return }
            storedTintColor = tintColor
        }
    }
    private var storedTintColor: UIColor?
    
    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            updateVisualState()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            guard isSelected != oldValue else { return }
            updateVisualState()
        }
    }
    
    private var isVisuallySelected = false
    private func updateVisualState() {
        let shouldSelect = isHighlighted || isSelected
        guard shouldSelect != isVisuallySelected else { return }
        isVisuallySelected = shouldSelect
        let tintColor = storedTintColor ?? superview?.tintColor ?? .black
        
        let animator = UIViewPropertyAnimator(duration: 0.32, dampingRatio: 0.64) {
            self.layer.backgroundColor = shouldSelect ? tintColor.cgColor : UIColor.white.cgColor
            self.tintColor = shouldSelect ? .white : tintColor
            self.transform = shouldSelect ? CGAffineTransform.identity.scaledBy(x: self.selectedScale, y: self.selectedScale) : .identity
        }
        animator.isInterruptible = true
        animator.startAnimation()
    }

}
