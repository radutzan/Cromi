//
//  ForkModalHeaderView.swift
//  Fork
//
//  Created by Radu Dutzan on 2/9/18.
//  Copyright © 2018 BetterFood SpA. All rights reserved.
//

import RaduKit

class ForkModalHeaderView: NibLoadingView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var submitButton: UIButton!
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    var subtitle: String? {
        didSet {
            subtitleLabel.isHidden = subtitle == nil
            subtitleLabel.text = subtitle?.uppercased()
        }
    }
    
    override func updateFonts() {
//        titleLabel.font = .actionTitle
//        subtitleLabel.font = .uppercaseLabel
//        cancelButton.titleLabel?.font = .paragraph
//        submitButton.titleLabel?.font = .actionTitle
    }

}
