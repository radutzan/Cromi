//
//  SignHeaderView.swift
//  Cromi
//
//  Created by Radu Dutzan on 4/9/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import RaduKit

class SignHeaderView: NibLoadingView {
    
    var annotation: TransantiagoAnnotation? {
        didSet {
            reloadData()
        }
    }
    var style: SignStyle = .dark {
        didSet {
            let backgroundColor = style == .dark ? UIColor.black : UIColor.white
            let textColor = style == .dark ? UIColor.white : UIColor.black
            view.backgroundColor = backgroundColor
            pretitleLabel.textColor = textColor
            titleLabel.textColor = textColor
            subtitleLabel.textColor = textColor
        }
    }
    var number: Int? {
        didSet {
            numberLabel.isHidden = number == nil
            numberLabel.text = number != nil ? "\(number!)" : nil
        }
    }
    var pretitle: String? {
        didSet {
            pretitleLabel.isHidden = pretitle == nil
            pretitleLabel.text = pretitle
            if let pretitle = pretitle {
                pretitleLabel.attributedText = attributedString(from: pretitle, style: TypeStyle.preTitle)
            }
        }
    }
    @objc var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    var subtitle: String? {
        didSet {
            subtitleLabel.isHidden = subtitle == nil
            subtitleLabel.text = subtitle
        }
    }
    var isSubtitleSecondary: Bool = false {
        didSet {
            subtitleLabel.alpha = isSubtitleSecondary ? CromiSignConstants.secondaryOpacity : 1
        }
    }
    
    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private var metroImageView: UIImageView!
    @IBOutlet private var numberLabel: UILabel!
    @IBOutlet private var pretitleLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    
    private let bipBlueColor = CromiSignConstants.Color.bipBlue
    
    override func didLoadNibView() {
        view.layer.cornerRadius = SignConstants.cornerRadius
    }
    
    override func updateFonts() {
        pretitleLabel.text = pretitle
        titleLabel.font = .title
        subtitleLabel.font = .subtitleBold
        numberLabel.font = .titleBold
    }
    
    private func reloadData() {
        number = nil
        pretitle = nil
        title = nil
        subtitle = nil
        isSubtitleSecondary = false
        view.backgroundColor = UIColor.white
        view.layer.borderWidth = 0
        view.layer.borderColor = UIColor.clear.cgColor
        numberLabel.textColor = .black
        numberLabel.backgroundColor = .white
        numberLabel.layer.cornerRadius = 2
        metroImageView.isHidden = true
        
        guard let annotation = annotation else { return }
        
        title = annotation.title
        
        switch annotation {
        case let annotation as Stop:
            style = .dark
            number = annotation.number
            var stopTitle = annotation.title ?? ""
            if stopTitle.hasPrefix("Metro ") {
                stopTitle = stopTitle.replacingOccurrences(of: "Metro ", with: "")
                pretitle = "Metro"
            }
            title = stopTitle
            if let stopSubtitle = annotation.subtitle {
                subtitle = "con " + stopSubtitle
            }
            
        case let annotation as MetroStation:
            style = .light
            let metroTitle = annotation.title ?? ""
            if metroTitle.hasPrefix("Metro ") {
                title = metroTitle.replacingOccurrences(of: "Metro ", with: "")
            }
//            number = annotation.lineNumber // TODO: get real metro line number
            numberLabel.backgroundColor = annotation.lineColor // TODO: get real metro color
            numberLabel.layer.cornerRadius = 28 / 2 // TODO: make 28 a constant
            numberLabel.textColor = .white
            metroImageView.isHidden = false
            
        case let annotation as BipSpot:
            style = .light
            subtitle = annotation.address
            view.layer.borderWidth = 2
            view.layer.borderColor = bipBlueColor.cgColor
            isSubtitleSecondary = true
            
        default:
            return
        }
        
        stackView.setNeedsLayout()
        layoutIfNeeded()
    }

}
