//
//  InfoBanner.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/18/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

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
    
    override func didLoadNibView() {
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 5.5
        layer.shadowOpacity = 0.2
        doneButton.tapAction = { button in
            self.delegate?.infoBannerRequestedDismissal()
        }
    }

}
