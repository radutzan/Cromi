//
//  EmptyBipView.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/4/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import RaduKit

class EmptyBipView: NibLoadingView {

    @IBOutlet var button: UIButton!
    
    override func didLoadNibView() {
        button.setTitle("Add Card Title".localized(), for: .normal)
        heightAnchor.constraint(equalToConstant: 80).isActive = true
    }

}
