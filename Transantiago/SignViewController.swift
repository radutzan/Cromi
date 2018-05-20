//
//  SignViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 5/19/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import RaduKit

class SignViewController: UIViewController {
    
    @IBOutlet var signViewContainer: UIView!
    @IBOutlet var signTopConstraint: NSLayoutConstraint!
    @IBOutlet var signLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var signTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var signBottomConstraint: NSLayoutConstraint!
    var signMinHeightConstraint: NSLayoutConstraint?
    var signView: SignView? {
        didSet {
            setUp(containerView: signViewContainer, with: signView)
            
            guard let headerView = signView?.headerView else {
                if let heightConstraint = signMinHeightConstraint {
                    signViewContainer.removeConstraint(heightConstraint)
                    signMinHeightConstraint = nil
                }
                return
            }
            signMinHeightConstraint = signViewContainer.heightAnchor.constraint(greaterThanOrEqualTo: headerView.heightAnchor, multiplier: 1)
            signMinHeightConstraint?.priority = .required
            signMinHeightConstraint?.isActive = true
        }
    }
    var layoutInsets: UIEdgeInsets = .zero {
        didSet {
            layoutInsetsUpdated()
        }
    }
    var originRect: CGRect = .zero {
        didSet {
            guard originRect != oldValue else { return }
            originRectUpdated()
        }
    }
    var distanceFromOrigin: CGFloat = 8 {
        didSet {
            guard distanceFromOrigin != oldValue else { return }
            originRectUpdated()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp(containerView: signViewContainer, with: signView)
        layoutInsetsUpdated()
    }
    
    func showSign() {
        originRectUpdated()
        signView?.present(originSize: originRect.size, bottomOffset: layoutInsets.bottom)
    }
    
    func hideSign() {
        signView?.dismiss(targetSize: originRect.size, bottomOffset: layoutInsets.bottom)
    }
    
    private func originRectUpdated() {
        guard isViewLoaded, let signView = signView else { return }
        let originCenter = originRect.minX + (originRect.width / 2)
        signLeadingConstraint.constant = max(layoutInsets.left, originCenter - (signView.bounds.width / 2))
        signBottomConstraint.constant = max(layoutInsets.bottom + safeAreaInsets.bottom, (view.bounds.height - originRect.minY) + distanceFromOrigin)
    }
    
    private func layoutInsetsUpdated() {
        guard isViewLoaded else { return }
        signTopConstraint.constant = layoutInsets.top
        signTrailingConstraint.constant = layoutInsets.right
        originRectUpdated()
    }

}
