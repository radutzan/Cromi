//
//  BusAnnotationView.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/11/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import MapKit

class BusAnnotationView: MKAnnotationView {

    var color: UIColor = .black {
        didSet {
            updateColor()
        }
    }
    var bus: Bus? {
        didSet {
            updateBus()
        }
    }
    
    private var serviceLabel = UILabel()
    private var plateLabel = UILabel()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        commonInit()
        if let bus = annotation as? Bus {
            self.bus = bus
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        frame.size = CGSize(width: 40, height: 38)
        clipsToBounds = false
        
        serviceLabel.frame = CGRect(x: 0, y: 0, width: 40, height: 24)
        serviceLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        serviceLabel.textColor = .black
        serviceLabel.textAlignment = .center
        serviceLabel.adjustsFontSizeToFitWidth = true
        serviceLabel.allowsDefaultTighteningForTruncation = true
        serviceLabel.layer.backgroundColor = UIColor.white.cgColor
        serviceLabel.layer.cornerRadius = 8
        serviceLabel.layer.shadowPath = UIBezierPath(roundedRect: serviceLabel.bounds, cornerRadius: serviceLabel.layer.cornerRadius).cgPath
        serviceLabel.apply(shadow: .restingHigh)
        serviceLabel.layer.borderWidth = 2
        addSubview(serviceLabel)
        
        plateLabel.frame = CGRect(x: 0, y: 26, width: 40, height: 12)
        plateLabel.font = UIFont.systemFont(ofSize: 8, weight: .heavy)
        plateLabel.textAlignment = .center
        plateLabel.textColor = .white
        plateLabel.layer.cornerRadius = 3
        insertSubview(plateLabel, aboveSubview: serviceLabel)
    }
    
    private func updateBus() {
        guard let bus = bus else { return }
        serviceLabel.text = bus.serviceName.last!.isDigit ? bus.serviceName : bus.serviceName.lowercased() // C20 vs 405c
        plateLabel.frame.size.width = 60
        plateLabel.text = bus.plateNumber
        plateLabel.sizeToFit()
        plateLabel.frame.size.width += 6
        plateLabel.frame.size.height = 12
        plateLabel.frame.origin.x = (bounds.width - plateLabel.bounds.width) / 2
    }
    
    private func updateColor() {
        serviceLabel.layer.borderColor = color.cgColor
        serviceLabel.textColor = color
        plateLabel.layer.backgroundColor = color.cgColor
        if #available(iOS 12.0, *) {
            serviceLabel.layer.backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.black.cgColor : UIColor.white.cgColor
            plateLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
    }
    
    override func prepareForReuse() {
        color = .black
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateColor()
    }
}
