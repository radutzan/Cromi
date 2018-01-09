//
//  CromiViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/9/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class CromiViewController: UIViewController, CromiModalDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Modals
    private var presentedModal: CromiModalViewController?
    func modalWillPresent(modal: CromiModalViewController) {
        presentedModal = modal
    }
    
    func modalDidPresent(modal: CromiModalViewController) {
    }
    
    func modalWillDismiss(modal: CromiModalViewController) {
        presentedModal = nil
    }
    
    func modalDidDismiss(modal: CromiModalViewController) {
    }
    
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return presentedModal
    }

}
