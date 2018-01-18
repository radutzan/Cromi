//
//  Extras.swift
//  Cromi
//
//  Created by Radu Dutzan on 11/17/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit

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
    // hex utilities from http://stackoverflow.com/questions/24263007/how-to-use-hex-colour-values-in-swift-ios#24263296
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
    
    convenience init(netHex: Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
    
    convenience init(hexString: String) {
        var sanitizedString = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (sanitizedString.hasPrefix("#")) {
            sanitizedString.remove(at: sanitizedString.startIndex)
        }
        
        if sanitizedString.count != 6 {
            self.init(white: 0.7, alpha: 1)
            return
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string: sanitizedString).scanHexInt32(&rgbValue)
        self.init(netHex: Int(rgbValue))
    }
    
    func isLight() -> Bool {
        //  from: http://stackoverflow.com/a/29044899/1851965
        let components = self.cgColor.components
        let redBrightness   = ((components?[0])! * 299)
        let greenBrightness = ((components?[1])! * 587)
        let blueBrightness  = ((components?[2])! * 114)
        let brightness = (redBrightness + greenBrightness + blueBrightness) / 1000
        
        if brightness < 0.7 {
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

extension String {
    var isNumeric: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
}

extension Character {
    var isDigit: Bool {
        let digits: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return digits.contains(self)
    }
}

// MARK: - Subclasses
class TouchTransparentView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}

class TouchTransparentStackView: UIStackView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}

class TouchTransparentScrollView: UIScrollView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}

class ExtraTouchableView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for subview in subviews {
            let pointInSubview = subview.convert(point, from: self)
            if subview.bounds.contains(pointInSubview) {
                return subview.hitTest(pointInSubview, with: event)
            }
        }
        return super.hitTest(point, with: event)
    }
}

class ButtonTouchableView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled else { return nil }
        for subview in subviews {
            let pointInSubview = subview.convert(point, from: self)
            if subview.bounds.contains(pointInSubview) {
                let result = subview.hitTest(pointInSubview, with: event)
                if result is UIButton {
                    return result
                }
            }
        }
        return nil
    }
}

class ExtraTouchableScrollView: UIScrollView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for subview in subviews {
            let pointInSubview = subview.convert(point, from: self)
            if subview.bounds.contains(pointInSubview) {
                return subview.hitTest(pointInSubview, with: event)
            }
        }
        return super.hitTest(point, with: event)
    }
}
