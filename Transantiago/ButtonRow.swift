//
//  ModeControlRow.swift
//  Cromi
//
//  Created by Radu Dutzan on 11/30/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import RaduKit

struct ButtonItem {
    var image: UIImage
    var title: String
    var action: (UIButton) -> ()
    var isPrimary: Bool = false
    var isDestructive: Bool = false
    var isDisabled: Bool = false
    
    init(image: UIImage, title: String, action: @escaping (UIButton) -> (), isPrimary: Bool = false, isDestructive: Bool = false, isDisabled: Bool = false) {
        self.image = image
        self.title = title
        self.action = action
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
    }
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
            let button = FloatingButton(type: .custom)
            button.setImage(buttonItem.image, for: .normal)
            button.accessibilityLabel = buttonItem.title
            button.tapAction = buttonItem.action
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            stackView.addArrangedSubview(button)
        }
    }
    
    // MARK: - Presentation
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
            let animator = UIViewPropertyAnimator(duration: 0.34, dampingRatio: 0.82) {
                button.transform = CGAffineTransform.identity
            }
            animator.startAnimation(afterDelay: 0.04 * Double(index + 1))
        }
    }
    
    func dismiss(from: Int? = nil) {
        for (index, button) in stackView.arrangedSubviews.enumerated() {
            UIView.animate(withDuration: 0.48, delay: 0.06 * Double(index), usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                button.transform = CGAffineTransform(translationX: 0, y: self.hiddenYOffset)
            }) { finished in
            }
        }
    }
    
    // MARK: - State affecting
    func setIsEnabled(on indices: [Int], to enabled: Bool) {
        for index in indices {
            if index >= stackView.arrangedSubviews.count { continue }
            guard let button = stackView.arrangedSubviews[index] as? FloatingButton else { continue }
            button.isEnabled = enabled
        }
    }
    
    func setIsHighlighted(on indices: [Int], to highlighted: Bool) {
        for index in indices {
            if index >= stackView.arrangedSubviews.count { continue }
            guard let button = stackView.arrangedSubviews[index] as? FloatingButton else { continue }
            button.isHighlighted = highlighted
        }
    }
    
    func setIsSelected(on indices: [Int], to selected: Bool) {
        for index in indices {
            if index >= stackView.arrangedSubviews.count { continue }
            guard let button = stackView.arrangedSubviews[index] as? FloatingButton else { continue }
            button.isSelected = selected
        }
    }
    
    // MARK: - Touch transparency
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }

}
