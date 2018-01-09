//
//  Shadows.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/9/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

struct Shadow {
    var radius: CGFloat
    var offset: CGSize
    var opacity: Float
    var color = UIColor.black
    
    init(radius: CGFloat, offset: CGSize, opacity: Float, color: UIColor = .black) {
        self.radius = radius
        self.offset = offset
        self.opacity = opacity
        self.color = color
    }
    
    init(radius: CGFloat, offsetHeight: CGFloat, opacity: Float, color: UIColor = .black) {
        self.radius = radius
        self.offset = CGSize(width: 0, height: offsetHeight)
        self.opacity = opacity
        self.color = color
    }
}

extension UIView {
    func apply(shadow: Shadow) {
        layer.apply(shadow: shadow)
    }
}

extension CALayer {
    func apply(shadow: Shadow) {
        shadowRadius = shadow.radius
        shadowOpacity = shadow.opacity
        shadowOffset = shadow.offset
        shadowColor = shadow.color.cgColor
    }
}
