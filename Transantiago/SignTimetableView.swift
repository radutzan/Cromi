//
//  SignTimetableView.swift
//  Cromi
//
//  Created by Radu Dutzan on 4/10/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

class SignTimetableView: NibLoadingView {
    
    @IBOutlet private var timeStack: UIStackView!

    func add(hoursRow: SignHoursRowView) {
        timeStack.addArrangedSubview(hoursRow)
        timeStack.layoutIfNeeded()
    }

}
