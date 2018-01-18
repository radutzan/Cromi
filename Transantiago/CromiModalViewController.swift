//
//  CromiModalViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/1/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

// MARK: - CromiModalDelegate
protocol CromiModalDelegate: AnyObject {
    func modalWillPresent(modal: CromiModalViewController)
    func modalDidPresent(modal: CromiModalViewController)
    func modalWillDismiss(modal: CromiModalViewController)
    func modalDidDismiss(modal: CromiModalViewController)
}

// MARK: - CromiModalViewController
class CromiModalViewController: CromiViewController {
    
    weak var delegate: CromiModalDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.frame = UIScreen.main.bounds
    }
    
    // MARK: - Presentation
    override var isBeingPresented: Bool {
        return isPresenting
    }
    private var isPresenting = false
    let presentationActions: (CromiModalViewController) -> () = { weakSelf in
        weakSelf.setNeedsStatusBarAppearanceUpdate()
    }
    let presentationCompletionActions: (CromiModalViewController) -> () = { weakSelf in
        weakSelf.delegate?.modalDidPresent(modal: weakSelf)
        weakSelf.isPresenting = false
    }
    
    func present(on parentVC: UIViewController, completion: (() -> ())? = nil) {
        delegate?.modalWillPresent(modal: self)
        isPresenting = true
        parentVC.addChildViewController(self)
        parentVC.view.addSubview(view)
    }
    
    // MARK: - Dismissal
    override var isBeingDismissed: Bool {
        return isDismissing
    }
    private var isDismissing = false
    let dismissalActions: (CromiModalViewController) -> () = { weakSelf in
        weakSelf.setNeedsStatusBarAppearanceUpdate()
    }
    let dismissalCompletionActions: (CromiModalViewController) -> () = { weakSelf in
        weakSelf.delegate?.modalDidDismiss(modal: weakSelf)
        weakSelf.removeFromParentViewController()
        weakSelf.view.removeFromSuperview()
        weakSelf.isDismissing = false
    }
    
    @objc override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        delegate?.modalWillDismiss(modal: self)
        isDismissing = true
    }

}
