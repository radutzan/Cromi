//
//  CromiDefines.swift
//  Cromi
//
//  Created by Radu Dutzan on 10/18/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

extension TypeStyle {
    static let title     = TypeStyle(normalSize: proportionalTypeSize(for: 16), weight: .medium)
    static let titleBold = TypeStyle(normalSize: proportionalTypeSize(for: 16), weight: .bold)
    static let subtitle  = TypeStyle(normalSize: proportionalTypeSize(for: 12), weight: .semibold)
}

extension UIFont {
    static var title: UIFont { return TypeStyle.title.fontObject() }
    static var titleBold: UIFont { return TypeStyle.titleBold.fontObject() }
    static var subtitle: UIFont { return TypeStyle.subtitle.fontObject() }
}
