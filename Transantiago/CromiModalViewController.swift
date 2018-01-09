//
//  CromiModalViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/1/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

protocol CromiModalDelegate: AnyObject {
    func modalWillPresent(modal: CromiModalViewController)
    func modalDidPresent(modal: CromiModalViewController)
    func modalWillDismiss(modal: CromiModalViewController)
    func modalDidDismiss(modal: CromiModalViewController)
}

class CromiModalViewController: CromiViewController {
    
    weak var delegate: CromiModalDelegate?
    let presentationActions: (CromiModalViewController) -> () = { weakSelf in
        weakSelf.setNeedsStatusBarAppearanceUpdate()
    }
    let presentationCompletionActions: (CromiModalViewController) -> () = { weakSelf in
        weakSelf.delegate?.modalDidPresent(modal: weakSelf)
    }
    let dismissalActions: (CromiModalViewController) -> () = { weakSelf in
        weakSelf.setNeedsStatusBarAppearanceUpdate()
    }
    let dismissalCompletionActions: (CromiModalViewController) -> () = { weakSelf in
        weakSelf.delegate?.modalDidDismiss(modal: weakSelf)
        weakSelf.removeFromParentViewController()
        weakSelf.view.removeFromSuperview()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.frame = UIScreen.main.bounds
    }
    
    // MARK: - Presentation
    func present(on parentVC: UIViewController) {
        delegate?.modalWillPresent(modal: self)
        parentVC.addChildViewController(self)
        parentVC.view.addSubview(view)
    }
    
    @objc override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        delegate?.modalWillDismiss(modal: self)
    }

}
