//
//  StreetSignView.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import RaduKit

enum CromiSignStyle {
    case dark, light
}

struct CromiSignConstants {
    struct Color {
        static let bipBlue = UIColor(red: 0, green: 0.416, blue: 1, alpha: 1)
    }
    static let cornerRadius: CGFloat = 8
    static let secondaryOpacity: CGFloat = 0.64
    static let tertiaryOpacity: CGFloat = 0.36
}

class CromiSignView: SignView {
    var annotation: TransantiagoAnnotation? {
        didSet {
            reloadData()
            mainStackView.setNeedsLayout()
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    let signHeaderView = SignHeaderView()
    let mainStackView = UIStackView()
    
    // MARK: - Setup
    override func didLoadNibView() {
        super.didLoadNibView()
        headerView = signHeaderView
        signHeaderView.widthAnchor.constraint(equalToConstant: TypeStyle.proportionalContainerSize(for: 246, normalize: false)).isActive = true
        let headerHeightConstraint = signHeaderView.heightAnchor.constraint(equalToConstant: TypeStyle.proportionalContainerSize(for: 56, normalize: true))
        headerHeightConstraint.priority = .required
        headerHeightConstraint.isActive = true
        signHeaderView.style = .dark
        
        contentView = mainStackView
        mainStackView.axis = .vertical
        mainStackView.alignment = .fill
        mainStackView.distribution = .fill
        mainStackView.spacing = 0
    }
    
    func reloadData() {
        clearContentStack()
        signHeaderView.annotation = annotation
    }
    
    private func clearContentStack() {
        for view in mainStackView.arrangedSubviews {
            mainStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}
