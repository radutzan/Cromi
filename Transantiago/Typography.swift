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
    
    static func proportionalContainerSize(for originalSize: CGFloat, normalize: Bool = true) -> CGFloat {
        let normalizer: CGFloat = normalize ? 0.9 : 1
        let multiplier = max(sizeMultiplier * normalizer, 1)
        let result = round(originalSize * multiplier)
        return result
    }
    
    var normalSize: CGFloat
    var size: CGFloat {
        return isFixedSize ? normalSize : TypeStyle.proportionalTypeSize(for: normalSize)
    }
    var isFixedSize = false
    var weight: UIFont.Weight
    var letterSpacing: CGFloat?
    var textTransform: TextTransform?
    
    init(normalSize size: CGFloat, weight: UIFont.Weight, fixedSize: Bool = false, letterSpacing: CGFloat? = nil, textTransform: TextTransform? = nil) {
        self.normalSize = size
        self.weight = weight
        self.isFixedSize = fixedSize
        self.letterSpacing = letterSpacing
        self.textTransform = textTransform
    }
    
    func with(fontWeight weight: UIFont.Weight) -> TypeStyle {
        return TypeStyle(normalSize: normalSize, weight: weight, fixedSize: isFixedSize, letterSpacing: letterSpacing, textTransform: textTransform)
    }
    
    func fontObject() -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}

extension UIFont {
    static func digitSystemFontOfSize(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: TypeStyle.proportionalTypeSize(for: size), weight: weight)
        
        let fontDescriptorFeatureSettings = [[
            UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
            UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector], [
            UIFontDescriptor.FeatureKey.featureIdentifier: kStylisticAlternativesType,
            UIFontDescriptor.FeatureKey.typeIdentifier: kStylisticAltOneOnSelector]]
        
        let descriptor = baseFont.fontDescriptor.addingAttributes([
      UIFontDescriptor.AttributeName.featureSettings: fontDescriptorFeatureSettings])
        
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
        .font: UIFont.systemFont(ofSize: style.size, weight: style.weight),
        .kern: style.letterSpacing ?? 0])
    
    if let color = textColor {
        attributedString.addAttributes([.foregroundColor: color],
                                       range: NSMakeRange(0, string.count))
    }
    
    return attributedString
}
