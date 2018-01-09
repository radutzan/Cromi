//
//  EmptyBipView.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/4/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class EmptyBipView: NibLoadingView {

    @IBOutlet var button: UIButton!
    
    override func didLoadNibView() {
        button.setTitle(NSLocalizedString("Add Card Title", comment: ""), for: .normal)
    }

}
