//
//  ModeControlRow.swift
//  Cromi
//
//  Created by Radu Dutzan on 11/30/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

struct ButtonItem {
    var image: UIImage
    var title: String
    var action: (UIButton) -> ()
}

class ButtonRow: NibLoadingView {
    @IBOutlet private var stackView: UIStackView!

    var buttonItems: [ButtonItem] = [] {
        didSet {
            clearStackView()
            createAndAddButtons()
        }
    }
    
    private func clearStackView() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
    
    private func createAndAddButtons() {
        stackView.axis = buttonItems.count > 1 ? .horizontal : .vertical
        for buttonItem in buttonItems {
            let button = FloatingButton(type: .system)
            button.setImage(buttonItem.image, for: .normal)
            button.accessibilityLabel = buttonItem.title
            button.tapAction = buttonItem.action
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            stackView.addArrangedSubview(button)
        }
    }
    
    private var hiddenYOffset: CGFloat {
        var bottomMargin: CGFloat = 0
        if #available(iOS 11.0, *) {
            bottomMargin = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        return 80 + bottomMargin
    }
    
    func present() {
        for (index, button) in stackView.arrangedSubviews.enumerated() {
            button.transform = CGAffineTransform(translationX: 0, y: hiddenYOffset)
            UIView.animate(withDuration: 0.42, delay: 0.06 * Double(index + 1), usingSpringWithDamping: 0.76, initialSpringVelocity: 1, options: [], animations: {
                button.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }
    
    func dismiss(from: Int? = nil) {
        for (index, button) in stackView.arrangedSubviews.enumerated() {
            UIView.animate(withDuration: 0.52, delay: 0.08 * Double(index), usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                button.transform = CGAffineTransform(translationX: 0, y: self.hiddenYOffset)
            }) { finished in
            }
        }
    }
    
    // Touch transparency
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }

}
