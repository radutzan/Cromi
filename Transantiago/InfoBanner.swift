//
//  InfoBanner.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/18/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import RaduKit

protocol InfoBannerDelegate: AnyObject {
    func infoBannerRequestedDismissal()
}

class InfoBanner: NibLoadingView {
    
    weak var delegate: InfoBannerDelegate?

    @IBInspectable var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    @IBInspectable var message: String = "" {
        didSet {
            messageLabel.text = message
            setNeedsLayout()
        }
    }
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var doneButton: UIButton!
    @IBOutlet private var blurView: UIVisualEffectView!
    
    override func didLoadNibView() {
        apply(shadow: .floatingLow)
        doneButton.tapAction = { button in
            self.delegate?.infoBannerRequestedDismissal()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            blurView.effect = UIBlurEffect(style: .systemThinMaterial)
        } else {
            blurView.effect = UIBlurEffect(style: .extraLight)
        }
    }

}
