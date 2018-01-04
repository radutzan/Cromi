//
//  BipEntryView.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/4/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class BipEntryView: NibLoadingView {

    @IBOutlet private var entryView: UIView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var numberField: UITextField!
    @IBOutlet private var nameField: UITextField!
    @IBOutlet private var colorSelectionArea: UIView!
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var addButton: UIButton!
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 280, height: entryView.bounds.height)
    }

}
