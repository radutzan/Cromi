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
                    add(view: view)
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
    
    private func add(view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(view)
        view.apply(shadow: .floatingHigh)
    }
    
    func append(cardView: BipCardView) {
        preventClearing = true
        views.append(cardView)
        cardView.isHidden = true
        add(view: cardView)
        let appendAnimator = UIViewPropertyAnimator(duration: 0.52, dampingRatio: 1) {
            cardView.isHidden = false
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        appendAnimator.startAnimation()
    }
    
    func removeView(with cardNumber: Int, animateAlongside: (() -> ())? = nil) {
        for (index, view) in views.enumerated() {
            guard let view = view as? BipCardView, view.cardNumber == cardNumber else { continue }
//            view.closeOptions()
            view.setAnchorPoint(CGPoint(x: 0.5, y: 0))
            UIView.animate(withDuration: 0.52, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
                view.isHidden = true
                view.alpha = 0
                view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.setNeedsLayout()
                self.layoutIfNeeded()
                animateAlongside?()
            }) { finished in
                self.preventClearing = true
                self.stackView.removeArrangedSubview(view)
                view.removeFromSuperview()
                self.views.remove(at: index)
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: listView.intrinsicContentSize.width, height: listView.bounds.height)
    }
}

class BipListInfoContainerView: UIView {}
