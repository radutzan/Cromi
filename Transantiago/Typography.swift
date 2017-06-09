//
//  Typography.swift
//  Cromi
//
//  Created by Radu Dutzan on 5/8/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

struct TypeStyle {
    enum TextTransform {
        case none, lowercase, uppercase
    }
    
    var size: CGFloat
    var weight: CGFloat
    var letterSpacing: CGFloat?
    var textTransform: TextTransform?
    
    init(size: CGFloat, weight: CGFloat, letterSpacing: CGFloat? = nil, textTransform: TextTransform? = nil) {
        self.size = size
        self.weight = weight
        self.letterSpacing = letterSpacing
        self.textTransform = textTransform
    }
    
    static let title     = TypeStyle(size: proportionalTypeSize(for: 16), weight: UIFontWeightMedium)
    static let titleBold = TypeStyle(size: proportionalTypeSize(for: 16), weight: UIFontWeightBold)
    
    static let subtitle  = TypeStyle(size: proportionalTypeSize(for: 12), weight: UIFontWeightSemibold)
    
    static var sizeMultiplier: CGFloat {
        let normalBodySize: CGFloat = 17
        let currentBodySize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).pointSize
        let multiplier = currentBodySize / normalBodySize
        return multiplier
    }
    
    static func proportionalTypeSize(for originalSize: CGFloat) -> CGFloat {
        let result = round(originalSize * sizeMultiplier)
        return result
    }
    
    static func proportionalContainerSize(for originalSize: CGFloat) -> CGFloat {
        let multiplier = max(sizeMultiplier, 1)
        let result = round(originalSize * multiplier)
        return result
    }
}

extension UIFont {
    static var title: UIFont {
        return  UIFont.systemFont(ofSize: TypeStyle.title.size,     weight: TypeStyle.title.weight)
    }
    static var titleBold: UIFont {
        return  UIFont.systemFont(ofSize: TypeStyle.titleBold.size, weight: TypeStyle.titleBold.weight)
    }
    static var subtitle: UIFont {
        return  UIFont.systemFont(ofSize: TypeStyle.subtitle.size,  weight: TypeStyle.subtitle.weight)
    }
}

extension UIFont {
    static func digitSystemFontOfSize(size: CGFloat, weight: CGFloat) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: TypeStyle.proportionalTypeSize(for: size), weight: weight)
        
        let fontDescriptorFeatureSettings = [[
                UIFontFeatureTypeIdentifierKey: kNumberSpacingType,
            UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector], [
                UIFontFeatureTypeIdentifierKey: kStylisticAlternativesType,
            UIFontFeatureSelectorIdentifierKey: kStylisticAltOneOnSelector]]
        
        let descriptor = baseFont.fontDescriptor.addingAttributes([
      UIFontDescriptorFeatureSettingsAttribute: fontDescriptorFeatureSettings])
        
        return UIFont(descriptor: descriptor, size: size)
    }
}

func attributedString(from string: String, style: TypeStyle, textColor: UIColor? = nil) -> NSMutableAttributedString {
    var string = string
    switch style.textTransform {
    case .some(.lowercase):
        string = string.lowercased()
    case .some(.uppercase):
        string = string.uppercased()
    default:
        break
    }
    
    let attributedString = NSMutableAttributedString(string: string, attributes: [
        NSFontAttributeName: UIFont.systemFont(ofSize: style.size, weight: style.weight),
        NSKernAttributeName: style.letterSpacing ?? 0])
    
    if let color = textColor {
        attributedString.addAttributes([
            NSForegroundColorAttributeName: color],
                                     range: NSMakeRange(0, string.characters.count))
    }
    
    return attributedString
}
