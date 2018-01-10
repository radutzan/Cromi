//
//  BipListView.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/4/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class BipListView: NibLoadingView {

    @IBOutlet private var listView: UIView!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet private var stackView: UIStackView!
    var views: [UIView] = [] {
        didSet {
            clearStackView()
            for view in views {
                stackView.addArrangedSubview(view)
                view.heightAnchor.constraint(equalToConstant: 80).isActive = true
                view.apply(shadow: .floatingHigh)
            }
            stackView.layoutIfNeeded()
        }
    }
    
    private func clearStackView() {
        for view in stackView.arrangedSubviews {
            if view is BipListInfoContainerView { continue }
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: listView.intrinsicContentSize.width, height: listView.bounds.height)
    }
}

class BipListInfoContainerView: UIView {}
