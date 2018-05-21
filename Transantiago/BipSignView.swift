//
//  StreetSignView.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import RaduKit

class BipSignView: CromiSignView {
    
    // MARK: - Setup
    override func didLoadNibView() {
        super.didLoadNibView()
    }
    
    override func reloadData() {
        super.reloadData()
        guard let annotation = annotation as? BipSpot else { return }
        let isBip = !(annotation is MetroStation)
        view.backgroundColor = isBip ? CromiSignConstants.Color.bipBlue : .white
        
        guard annotation.operationHours.count > 0 else { return }
        let timetableView = SignTimetableView()
        timetableView.style = isBip ? .dark : .light
        timetableView.topConstraint.constant = isBip ? 5 : 0
        timetableView.operationHours = annotation.operationHours
        mainStackView.addArrangedSubview(timetableView)
    }
}
