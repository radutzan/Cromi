//
//  SignTimetableView.swift
//  Cromi
//
//  Created by Radu Dutzan on 4/10/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import RaduKit

class SignTimetableView: NibLoadingView {
    
    @IBOutlet private var timeStack: UIStackView!
    @IBOutlet private(set) var topConstraint: NSLayoutConstraint!
    @IBOutlet private(set) var bottomConstraint: NSLayoutConstraint!
    
    var operationHours: [OperationHours] = [] {
        didSet {
            updateTimetable()
        }
    }
    
    var style: CromiSignStyle = .light {
        didSet {
            guard style != oldValue else { return }
            for row in timeStack.arrangedSubviews {
                guard let hoursRow = row as? SignHoursRowView else { continue }
                hoursRow.style = style
            }
        }
    }
    
    private func updateTimetable() {
        for view in timeStack.arrangedSubviews {
            timeStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        for hours in operationHours {
            let hoursRow = SignHoursRowView()
            hoursRow.days = hours.rangeTitle
            hoursRow.hours = "\(hours.start) \("to".localized()) \(hours.end)"
            hoursRow.style = style
            add(hoursRow: hoursRow)
        }
    }

    func add(hoursRow: SignHoursRowView) {
        timeStack.addArrangedSubview(hoursRow)
        timeStack.layoutIfNeeded()
    }

}
