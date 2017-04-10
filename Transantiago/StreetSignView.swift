//
//  StreetSignView.swift
//  Transantiago
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit

enum SignStyle {
    case dark, light
}

struct SignConstants {
    struct Color {
        static let bipBlue = UIColor(red: 0, green: 0.416, blue: 1, alpha: 1)
    }
    static let cornerRadius: CGFloat = 5
}

class StreetSignView: NibLoadingView {

    var annotation: TransantiagoAnnotation? {
        didSet {
            reloadData()
            headerView.annotation = annotation
        }
    }
    private var style: SignStyle = .dark {
        didSet {
            let backgroundColor = style == .dark ? UIColor.black : UIColor.white
            view.backgroundColor = backgroundColor
            headerView.style = style
        }
    }
    
    @IBOutlet private var signView: UIView!
    @IBOutlet private var mainStackView: UIStackView!
    @IBOutlet private var headerView: SignHeaderView!
    
    private let bipBlueColor = SignConstants.Color.bipBlue
    
    private var didPerformInitialSetup = false
    private func perfornInitialSetupIfNeeded() {
        if didPerformInitialSetup { return }
        alpha = 0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 17)
        layer.shadowRadius = 11
        layer.shadowOpacity = 0.2
        signView.layer.cornerRadius = SignConstants.cornerRadius
        signView.layer.masksToBounds = true
        didPerformInitialSetup = true
    }
    
    private func reloadData() {
        perfornInitialSetupIfNeeded()
        clearContentStack()
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.clear.cgColor
        
        guard let annotation = annotation else { return }
        
        switch annotation {
        case let annotation as Stop:
            // TODO: load content subviews for stop (services)
            return
            
        case let annotation as MetroStation:
            // TODO: load content subviews for metro (times)
            return
            
        case let annotation as BipSpot:
            // TODO: load content subviews for bip (times)
            return
            
        default:
            return
        }
        
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        view.frame.origin = CGPoint.zero
    }
    
    private func clearContentStack() {
        for view in mainStackView.arrangedSubviews {
            if view == headerView { continue }
            mainStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 220, height: signView.bounds.height)
    }

}
