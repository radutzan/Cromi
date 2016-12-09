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

class StreetSignView: NibLoadingView {

    var annotation: TransantiagoAnnotation? {
        didSet {
            reloadData()
        }
    }
    private var style: SignStyle = .dark {
        didSet {
            let backgroundColor = style == .dark ? UIColor.black : UIColor.white
            let textColor = style == .dark ? UIColor.white : UIColor.black
            view.backgroundColor = backgroundColor
            pretitleLabel.textColor = textColor
            titleLabel.textColor = textColor
            subtitleLabel.textColor = textColor
        }
    }
    private var accessoryImage: UIImage? {
        didSet {
            accessoryView.isHidden = accessoryImage == nil
            accessoryImageView.isHidden = accessoryImage == nil
            accessoryImageView.image = accessoryImage
        }
    }
    private var stopNumber: Int? {
        didSet {
            accessoryView.isHidden = stopNumber == nil
            stopNumberLabel.isHidden = stopNumber == nil
            stopNumberLabel.text = stopNumber != nil ? "\(stopNumber!)" : nil
        }
    }
    private var pretitle: String? {
        didSet {
            pretitleLabel.isHidden = pretitle == nil
            pretitleLabel.text = pretitle
        }
    }
    private var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    private var subtitle: String? {
        didSet {
            subtitleLabel.isHidden = subtitle == nil
            subtitleLabel.text = subtitle
        }
    }
    private var isSubtitleSecondary: Bool = false {
        didSet {
            subtitleLabel.alpha = isSubtitleSecondary ? 0.55 : 1
        }
    }
    
    @IBOutlet private var mainStackView: UIStackView!
    @IBOutlet private var headerView: UIView!
    @IBOutlet private var accessoryView: UIView!
    @IBOutlet private var accessoryImageView: UIImageView!
    @IBOutlet private var stopNumberLabel: UILabel!
    @IBOutlet private var pretitleLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var contentStackView: UIStackView!
    
    private let bipBlueColor = UIColor(red: 0, green: 0.416, blue: 1, alpha: 1)
    
    private var didPerformInitialSetup = false
    private func perfornInitialSetupIfNeeded() {
        if didPerformInitialSetup { return }
        alpha = 0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 17)
        layer.shadowRadius = 11
        layer.shadowOpacity = 0.2
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.layer.borderWidth = 2
        stopNumberLabel.layer.cornerRadius = 2
        didPerformInitialSetup = true
    }
    
    private func reloadData() {
        perfornInitialSetupIfNeeded()
        clearContentStack()
        accessoryImage = nil
        stopNumber = nil
        pretitle = nil
        title = nil
        subtitle = nil
        isSubtitleSecondary = false
        contentView.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.clear.cgColor
        
        guard let annotation = annotation else {
            return
        }
        
        title = annotation.title
        
        switch annotation {
        case let annotation as Stop:
            style = .dark
            stopNumber = annotation.number
            var stopTitle = annotation.title ?? ""
            if stopTitle.hasPrefix("Metro ") {
                stopTitle = stopTitle.replacingOccurrences(of: "Metro ", with: "")
                pretitle = "Metro"
            }
            title = stopTitle
            
        case let annotation as MetroStation:
            style = .light
            let metroTitle = annotation.title ?? ""
            if metroTitle.hasPrefix("Metro ") {
                title = metroTitle.replacingOccurrences(of: "Metro ", with: "")
            }
            accessoryImage = #imageLiteral(resourceName: "sign accessory metro")
            
        case let annotation as BipSpot:
            style = .light
            subtitle = annotation.address
            contentView.backgroundColor = bipBlueColor
            view.layer.borderColor = bipBlueColor.cgColor
            isSubtitleSecondary = true
            
        default:
            return
        }
        
        contentStackView.setNeedsLayout()
        mainStackView.setNeedsLayout()
    }
    
    private func clearContentStack() {
        for view in contentStackView.arrangedSubviews {
            contentStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

}
