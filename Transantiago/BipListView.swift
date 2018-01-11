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
    private var preventClearing = false
    var views: [UIView] = [] {
        didSet {
            if !preventClearing {
                clearStackView()
                for view in views {
                    view.translatesAutoresizingMaskIntoConstraints = false
                    stackView.addArrangedSubview(view)
                    view.apply(shadow: .floatingHigh)
                }
                stackView.layoutIfNeeded()
            }
            preventClearing = false
        }
    }
    
    private func clearStackView() {
        for view in stackView.arrangedSubviews {
            if view is BipListInfoContainerView { continue }
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
    
    func removeView(with cardNumber: Int, animateAlongside: (() -> ())? = nil) {
        for (index, view) in views.enumerated() {
            guard let view = view as? BipCardView, view.cardNumber == cardNumber else { continue }
            UIView.animate(withDuration: 2.36, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
                view.isHidden = true//heightConstraint.constant = 0
                view.alpha = 0
//                self.stackView.layoutIfNeeded()
                animateAlongside?()
            }) { finished in
                self.preventClearing = true
                self.stackView.removeArrangedSubview(view)
                view.removeFromSuperview()
                self.views.remove(at: index)
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: listView.intrinsicContentSize.width, height: listView.bounds.height)
    }
}

class BipListInfoContainerView: UIView {}
