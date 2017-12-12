//
//  StopAnnotationView.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/4/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import MapKit

class StopAnnotationView: MKAnnotationView {

    var color: UIColor = .black {
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
        let shouldInvert = (!isinverted && isSelected) || (isinverted && !isSelected)
        pinContentImageView.tintColor = shouldInvert ? color : .white
        pinContentImageView.backgroundColor = shouldInvert ? .white : color
    }
    
    override func prepareForReuse() {
        color = .black
    }
    
}
