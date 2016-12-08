//
//  Extras.swift
//  Cromi
//
//  Created by Radu Dutzan on 11/17/16.
//  Copyright © 2016 Onda. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: - Free functions
func delay(_ delay: Double, closure: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func background(_ closure: @escaping ()->()) {
    DispatchQueue.global(qos: .default).async(execute: closure)
}

func mainThread(_ closure: @escaping ()->()) {
    DispatchQueue.main.async(execute: closure)
}

// MARK: - Extensions
extension UIImageView {
    func transition(toImage image: UIImage?, duration: CFTimeInterval = 0.16, type: String = kCATransitionFade) {
        self.image = image
        
        let transition = CATransition()
        transition.duration = duration
        transition.type = type
        layer.add(transition, forKey: nil)
    }
}

extension UIColor {
    func isLight() -> Bool {
        //  from: http://stackoverflow.com/a/29044899/1851965
        let components = self.cgColor.components
        let redBrightness   = ((components?[0])! * 299)
        let greenBrightness = ((components?[1])! * 587)
        let blueBrightness  = ((components?[2])! * 114)
        let brightness = (redBrightness + greenBrightness + blueBrightness) / 1000
        
        if brightness < 0.5 {
            return false
        } else {
            return true
        }
    }
}

extension CGFloat {
    func progressLimited() -> CGFloat {
        var limitedSelf = Swift.max(0, self)
        limitedSelf = Swift.min(1, limitedSelf)
        return limitedSelf
    }
}

extension CGPoint {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
    
    func ceiled() -> CGPoint {
        return CGPoint(x: ceil(self.x), y: ceil(self.y))
    }
    
    func rounded() -> CGPoint {
        return CGPoint(x: round(self.x), y: round(self.y))
    }
    
    func floored() -> CGPoint {
        return CGPoint(x: floor(self.x), y: floor(self.y))
    }
}

extension CGRect {
    init(size: CGSize, center: CGPoint) {
        self.size = size
        self.origin = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
    }
    
    func ceiled() -> CGRect {
        return CGRect(x: ceil(self.origin.x), y: ceil(self.origin.y), width: ceil(self.size.width), height: ceil(self.size.height))
    }
    
    func rounded() -> CGRect {
        return CGRect(x: round(self.origin.x), y: round(self.origin.y), width: round(self.size.width), height: round(self.size.height))
    }
    
    func floored() -> CGRect {
        return CGRect(x: floor(self.origin.x), y: floor(self.origin.y), width: floor(self.size.width), height: floor(self.size.height))
    }
}
