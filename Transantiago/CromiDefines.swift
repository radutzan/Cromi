//
//  CromiDefines.swift
//  Cromi
//
//  Created by Radu Dutzan on 10/18/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

extension TypeStyle {
    static let title     = TypeStyle(
        normalSize: proportionalTypeSize(for: 17),
        weight: .semibold)
    
    static let titleBold = title.with(fontWeight: .bold)
    
    static let serviceName = TypeStyle(
        normalSize: proportionalTypeSize(for: 17),
        weight: .bold)
    
    static let preTitle  = TypeStyle(
        normalSize: proportionalTypeSize(for: 10),
        weight: .heavy,
        fixedSize: true,
        letterSpacing: 0,
        textTransform: .uppercase)
    
    static let subtitle  = TypeStyle(
        normalSize: proportionalTypeSize(for: 13),
        weight: .bold)
    
    static let subtitleBold  = subtitle.with(fontWeight: .bold)
}

extension UIFont {
    static var title: UIFont { return TypeStyle.title.fontObject() }
    static var titleBold: UIFont { return TypeStyle.titleBold.fontObject() }
    static var serviceName: UIFont { return TypeStyle.serviceName.fontObject() }
    static var subtitle: UIFont { return TypeStyle.subtitle.fontObject() }
    static var subtitleBold: UIFont { return TypeStyle.subtitleBold.fontObject() }
}
