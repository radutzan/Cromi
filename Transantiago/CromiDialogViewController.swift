//
//  CromiDialogViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/9/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class CromiDialogViewController: UIViewController {

    @IBOutlet private var backgroundBlur: UIVisualEffectView!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var containerViewVerticalCenterConstraint: NSLayoutConstraint!
    var contentView: UIView?
    
    convenience init(dialogView: UIView) {
        self.init(nibName: nil, bundle: nil)
        self.view.alpha = 1
        self.contentView = dialogView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillChangeFrame, object: nil, queue: nil) { (notification) in
            guard let userInfo = notification.userInfo else { return }
            self.updateForKeyboard(with: userInfo)
        }
        
        view.frame = UIScreen.main.bounds
        containerView.apply(shadow: Shadow.floatingHigh)
    }
    
    override func viewWillLayoutSubviews() {
        contentView?.frame = containerView.bounds
    }
    
    func present(on parentVC: UIViewController) {
        guard let contentView = contentView else { return }
        
        backgroundBlur.effect = nil
        parentVC.addChildViewController(self)
        parentVC.view.addSubview(view)
        
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 12
        containerView.addSubview(contentView)
        
        containerView.heightAnchor.constraint(equalToConstant: contentView.intrinsicContentSize.height).isActive = true
        containerView.widthAnchor.constraint(equalToConstant: contentView.intrinsicContentSize.width).isActive = true
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        containerView.transform = CGAffineTransform(rotationAngle: -1).concatenating(CGAffineTransform(translationX: view.bounds.width, y: -view.bounds.height / 2))
        UIView.animate(withDuration: 0.64, delay: 0, usingSpringWithDamping: 0.86, initialSpringVelocity: 1, options: [], animations: {
            self.backgroundBlur.effect = UIBlurEffect(style: .dark)
            self.containerView.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    enum InteractionResult {
        case success, cancelled
    }
    
    func dismiss(with result: InteractionResult) {
        let targetTransform = result == .cancelled ? CGAffineTransform(rotationAngle: 1).concatenating(CGAffineTransform(translationX: 128, y: view.bounds.height)) : CGAffineTransform(rotationAngle: -0.5).concatenating(CGAffineTransform(translationX: 128, y: -view.bounds.height))
        
        UIView.animate(withDuration: 0.58, delay: 0, usingSpringWithDamping: 0, initialSpringVelocity: 0, options: [], animations: {
            self.backgroundBlur.effect = nil
            self.containerView.transform = targetTransform
        }) { finished in
            self.contentView?.removeFromSuperview()
            self.contentView = nil
            self.removeFromParentViewController()
            self.view.removeFromSuperview()
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
