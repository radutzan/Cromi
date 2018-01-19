//
//  CromiDialogViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/9/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class CromiDialogViewController: CromiModalViewController {

    @IBOutlet private var backgroundBlur: UIVisualEffectView!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var containerViewVerticalCenterConstraint: NSLayoutConstraint!
    var contentView: UIView? {
        didSet {
            if oldValue != nil {
                oldValue?.removeFromSuperview()
            }
            setUpContentView()
        }
    }
    
    convenience init(dialogView: UIView) {
        self.init(nibName: nil, bundle: nil)
        self.view.alpha = 1
        self.contentView = dialogView
        setUpContentView()
    }
    
    private func setUpContentView() {
        guard let contentView = contentView else { return }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 12
        containerView.addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillChangeFrame, object: nil, queue: nil) { (notification) in
            guard let userInfo = notification.userInfo else { return }
            self.updateForKeyboard(with: userInfo)
        }
        
        containerView.apply(shadow: .floatingHigh)
    }
    
//    override func viewWillLayoutSubviews() {
//        contentView?.frame = containerView.bounds
//    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func present(on parentVC: UIViewController, completion: (() -> ())? = nil) {
        guard contentView != nil else { return }
        super.present(on: parentVC)
        
        backgroundBlur.effect = nil
//        containerView.heightAnchor.constraint(equalToConstant: contentView.intrinsicContentSize.height).isActive = true
//        containerView.widthAnchor.constraint(equalToConstant: contentView.intrinsicContentSize.width).isActive = true
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        containerView.transform = CGAffineTransform(rotationAngle: -1).concatenating(CGAffineTransform(translationX: view.bounds.width, y: -view.bounds.height / 2))
        UIView.animate(withDuration: 0.64, delay: 0, usingSpringWithDamping: 0.86, initialSpringVelocity: 1, options: [], animations: {
            self.setNeedsStatusBarAppearanceUpdate()
            self.backgroundBlur.effect = UIBlurEffect(style: .dark)
            self.containerView.transform = CGAffineTransform.identity
        }) { finished in
            completion?()
            self.presentationCompletionActions(self)
        }
    }
    
    enum InteractionResult {
        case success, cancelled
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        dismiss(with: .cancelled)
    }
    
    func dismiss(with result: InteractionResult) {
        delegate?.modalWillDismiss(modal: self)
        let targetTransform = result == .cancelled ? CGAffineTransform(rotationAngle: 1).concatenating(CGAffineTransform(translationX: 128, y: view.bounds.height)) : CGAffineTransform(rotationAngle: -0.5).concatenating(CGAffineTransform(translationX: 128, y: -view.bounds.height))
        
        UIView.animate(withDuration: 0.58, delay: 0, usingSpringWithDamping: 0, initialSpringVelocity: 0, options: [], animations: {
            self.setNeedsStatusBarAppearanceUpdate()
            self.backgroundBlur.effect = nil
            self.containerView.transform = targetTransform
        }) { finished in
            self.contentView?.removeFromSuperview()
            self.contentView = nil
            self.dismissalCompletionActions(self)
        }
    }
    
    private func updateForKeyboard(with userInfo: [AnyHashable: Any]) {
        guard let frame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        let effectiveHeight = view.bounds.height - frame.minY
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0, options: UIViewAnimationOptions(rawValue: animationCurve.uintValue), animations: {
            self.containerViewVerticalCenterConstraint.constant = -effectiveHeight / 2
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}
