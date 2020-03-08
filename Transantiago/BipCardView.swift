//
//  BipCardView.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/4/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import RaduKit

protocol BipCardViewDelegate: AnyObject {
    func bipCardViewWillRevealOptions(cardView: BipCardView)
    func bipCardViewWillHideOptions(cardView: BipCardView)
    func bipCardViewTapped(cardView: BipCardView)
}

class BipCardView: NibLoadingView {
    
    weak var delegate: BipCardViewDelegate?

    var cardNumber: Int = 0
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    @IBOutlet var balanceLabel: UILabel!
    @IBOutlet var updatedDateLabel: UILabel!
    var color: UIColor = UIColor.blue {
        didSet {
            view.backgroundColor = color
            let isLight = color.isLight()
            let textColor: UIColor = isLight ? .black : .white
            nameLabel.textColor = textColor
            metadataLabel.textColor = textColor
            balanceLabel.textColor = textColor
            updatedDateLabel.textColor = textColor
        }
    }
    var editAction: ((Int, String, UIColor) -> ())?
    var deleteAction: ((Int, String, UIColor) -> ())?
    
    // MARK: - Internal properties
    private var optionItems: [ButtonItem] {
        return [ButtonItem(image: #imageLiteral(resourceName: "button edit"), title: "Edit".localized(), action: { button in
            self.editAction?(self.cardNumber, self.nameLabel.text ?? "", self.color)
        }), ButtonItem(image: #imageLiteral(resourceName: "button trash"), title: "Delete".localized(), action: { button in
            self.deleteAction?(self.cardNumber, self.nameLabel.text ?? "", self.color)
        })]
    }
    private let optionsContainerView = UIView()
    private(set) var optionsPanRecognizer: UIPanGestureRecognizer!
    private var tapRecognizer: UITapGestureRecognizer!
    private(set) var heightConstraint: NSLayoutConstraint!
    
    // MARK: - Setup
    private let buttonSize: CGFloat = 40
    private let buttonSeparation: CGFloat = 12
    override func didLoadNibView() {
        optionsPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handle(pan:)))
        addGestureRecognizer(optionsPanRecognizer)
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handle(tap:)))
        addGestureRecognizer(tapRecognizer)
        
        heightConstraint = view.heightAnchor.constraint(equalToConstant: 80)
        heightConstraint.isActive = true
        
        for buttonItem in optionItems {
            let button = FloatingButton(type: .custom)
            button.size = buttonSize
            button.shadow = .none
            button.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
            button.setImage(buttonItem.image, for: .normal)
            button.accessibilityLabel = buttonItem.title
            button.tapAction = buttonItem.action
            if buttonItem.title == "Delete".localized() {
                button.tintColor = .red
            }
            optionsContainerView.addSubview(button)
        }
        optionsContainerView.alpha = 0
        addSubview(optionsContainerView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let totalContainerWidth = CGFloat(optionItems.count) * (buttonSize + buttonSeparation)
        optionsContainerView.frame = CGRect(x: bounds.width + buttonSeparation, y: 0, width: totalContainerWidth, height: bounds.height)
        for (index, button) in optionsContainerView.subviews.enumerated() {
            guard button is FloatingButton else { continue }
            button.frame.origin = CGPoint(x: buttonSeparation + CGFloat(index) * (buttonSize + buttonSeparation), y: (bounds.height - buttonSize) / 2)
        }
    }
    
    // MARK: - Options
    @objc func closeOptions() {
        toggleOptions(open: false)
    }
    
    private var isPresentingOptions = false
    private var minTranslationX: CGFloat {
        return -(optionsContainerView.bounds.width + buttonSeparation)
    }
    
    private func toggleOptions(open: Bool) {
        if open {
            delegate?.bipCardViewWillRevealOptions(cardView: self)
        } else {
            delegate?.bipCardViewWillHideOptions(cardView: self)
        }
        let duration: TimeInterval = open ? 0.32 : 0.42
        let damping: CGFloat = open ? 0.82 : 0.8
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: damping, animations: {
            self.transform = open ? CGAffineTransform(translationX: self.minTranslationX, y: 0) : .identity
            self.optionsContainerView.alpha = open ? 1 : 0
            self.isPresentingOptions = open
        })
        animator.startAnimation()
    }
    
    private var feedbackGenerator = UISelectionFeedbackGenerator()
    private func toggleProposeDeleteSwipe(on: Bool) {
        guard isProposingDeleteSwipe != on else { return }
        for view in optionsContainerView.subviews {
            guard let button = view as? FloatingButton, button.accessibilityLabel == "Delete".localized() else { continue }
            isProposingDeleteSwipe = on
            button.isSelected = on
            feedbackGenerator.selectionChanged()
        }
    }
    
    // MARK: - Touches
    private var initialTransformTX: CGFloat = 0
    private var deleteSwipeExtraThreshold: CGFloat = 32
    private var isProposingDeleteSwipe = false
    @objc private func handle(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            feedbackGenerator.prepare()
            initialTransformTX = transform.tx
            
        case .changed:
            let gestureTranslationX = pan.translation(in: self.view).x
            var proposedTranslation = initialTransformTX + gestureTranslationX
            let resistanceDivider: CGFloat = 3
            
            if proposedTranslation < minTranslationX {
                let baseTranslation = !isPresentingOptions ? minTranslationX : 0
                proposedTranslation = minTranslationX + ((gestureTranslationX - baseTranslation) / resistanceDivider)
            } else if proposedTranslation > 0 {
                let baseTranslation = isPresentingOptions ? minTranslationX : 0
                proposedTranslation = (gestureTranslationX + baseTranslation) / resistanceDivider
            }
            transform = CGAffineTransform(translationX: proposedTranslation, y: 0)
            optionsContainerView.alpha = proposedTranslation / minTranslationX
            if proposedTranslation < minTranslationX - deleteSwipeExtraThreshold && !isProposingDeleteSwipe {
                toggleProposeDeleteSwipe(on: true)
            } else if isProposingDeleteSwipe && proposedTranslation >= minTranslationX - deleteSwipeExtraThreshold {
                toggleProposeDeleteSwipe(on: false)
            }
            
        default:
            guard !isProposingDeleteSwipe else {
                deleteAction?(cardNumber, nameLabel.text ?? "", color)
                return
            }
            var shouldPresentOptions = false
            let minVelocity: CGFloat = 820
            let currentVelocity = pan.velocity(in: self.view).x
            if !isPresentingOptions {
                if transform.tx < minTranslationX * 0.6 || currentVelocity < -minVelocity {
                    shouldPresentOptions = true
                } else {
                    shouldPresentOptions = false
                }
            } else {
                if transform.tx > minTranslationX * 0.4 || currentVelocity > minVelocity {
                    shouldPresentOptions = false
                } else {
                    shouldPresentOptions = true
                }
            }
            
            toggleOptions(open: shouldPresentOptions)
        }
    }
    
    @objc private func handle(tap: UITapGestureRecognizer) {
        delegate?.bipCardViewTapped(cardView: self)
        if isPresentingOptions {
            closeOptions()
        } else {
            editAction?(cardNumber, nameLabel.text ?? "", color)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for subview in subviews {
            let pointInSubview = subview.convert(point, from: self)
            if subview.bounds.contains(pointInSubview) {
                return subview.hitTest(pointInSubview, with: event)
            }
        }
        return super.hitTest(point, with: event)
    }
}
