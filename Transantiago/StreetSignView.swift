//
//  StreetSignView.swift
//  Transantiago
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit

enum SignStyle {
    case dark, light
}

struct SignConstants {
    struct Color {
        static let bipBlue = UIColor(red: 0, green: 0.416, blue: 1, alpha: 1)
    }
    static let cornerRadius: CGFloat = 5
    static let secondarySubtitleOpacity: CGFloat = 0.55
}

class StreetSignView: NibLoadingView {

    var annotation: TransantiagoAnnotation? {
        didSet {
            reloadData()
            headerView.annotation = annotation
        }
    }
    private var style: SignStyle = .dark {
        didSet {
            let backgroundColor = style == .dark ? UIColor.black : UIColor.white
            signView.backgroundColor = backgroundColor
            headerView.style = style
        }
    }
    
    @IBOutlet private var signView: UIView!
    @IBOutlet private var mainStackView: UIStackView!
    @IBOutlet private var headerView: SignHeaderView!
    
    private let bipBlueColor = SignConstants.Color.bipBlue
    
    private var didPerformInitialSetup = false
    private func performInitialSetupIfNeeded() {
        if didPerformInitialSetup { return }
        alpha = 0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 17)
        layer.shadowRadius = 11
        layer.shadowOpacity = 0.2
        signView.layer.cornerRadius = SignConstants.cornerRadius
        signView.layer.masksToBounds = true
        didPerformInitialSetup = true
    }
    
    private func reloadData() {
        performInitialSetupIfNeeded()
        clearContentStack()
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.clear.cgColor
        mainStackView.spacing = 0
        
        guard let annotation = annotation else { return }
        
        switch annotation {
        case let annotation as Stop:
            style = .dark
            
            var pendingServices: [Service] = []
            for service in annotation.services {
                pendingServices.append(service)
                
                if pendingServices.count == 2 || service == annotation.services.last! {
                    let serviceRowView = SignServiceRowView(services: pendingServices)
                    mainStackView.addArrangedSubview(serviceRowView)
                    mainStackView.layoutIfNeeded()
                    pendingServices = []
                }
            }
            
        case let annotation as BipSpot:
            style = .light
            let isBip = !(annotation is MetroStation)
            if isBip {
                signView.backgroundColor = bipBlueColor
                mainStackView.spacing = 5
            }
            
            let timetableView = SignTimetableView()
            for hours in annotation.operationHours {
                let hoursRow = SignHoursRowView()
                hoursRow.days = hours.rangeTitle
                hoursRow.hours = "\(hours.start) \(NSLocalizedString("to", comment: "")) \(hours.end)"
                if isBip { hoursRow.style = .dark }
                timetableView.add(hoursRow: hoursRow)
            }
            mainStackView.addArrangedSubview(timetableView)
            mainStackView.layoutIfNeeded()
            
        default:
            return
        }
        
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        view.frame.origin = CGPoint.zero
    }
    
    private func clearContentStack() {
        for view in mainStackView.arrangedSubviews {
            if view == headerView { continue }
            mainStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 220, height: signView.bounds.height)
    }

}
