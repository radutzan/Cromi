//
//  StopAnnotationView.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/4/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import MapKit

class StopAnnotationView: MKAnnotationView {

    var color: UIColor? {
        didSet {
            updateColor()
        }
    }
    override var isSelected: Bool {
        didSet {
            updateColor()
        }
    }
    var isinverted: Bool = false {
        didSet {
            updateColor()
        }
    }
    private var pinContentImageView = UIImageView(image: #imageLiteral(resourceName: "pin stop bus icon"))
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        self.image = #imageLiteral(resourceName: "pin stop base")
        pinContentImageView.frame = CGRect(x: 6, y: 3, width: 22, height: 24)
        pinContentImageView.contentMode = .center
        pinContentImageView.clipsToBounds = true
        pinContentImageView.layer.cornerRadius = 2
        addSubview(pinContentImageView)
    }
    
    private func updateColor() {
        var defaultColor = UIColor.black
        var invertedColor = UIColor.white
        if #available(iOS 12.0, *) {
            defaultColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
            invertedColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        let shouldInvert = (!isinverted && isSelected) || (isinverted && !isSelected)
        pinContentImageView.tintColor = shouldInvert ? (color ?? defaultColor) : invertedColor
        pinContentImageView.backgroundColor = shouldInvert ? invertedColor : (color ?? defaultColor)
    }
    
    override func prepareForReuse() {
        color = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateColor()
    }
    
}
