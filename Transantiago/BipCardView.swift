//
//  BipCardView.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/4/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class BipCardView: NibLoadingView {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    @IBOutlet var balanceLabel: UILabel!
    @IBOutlet var updatedDateLabel: UILabel!
    var color: UIColor = UIColor.blue {
        didSet {
            view.backgroundColor = color
        }
    }

}
