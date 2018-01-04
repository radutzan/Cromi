//
//  CromiModalViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/1/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

protocol CromiModalDelegate: AnyObject {
    func modalWillDismiss()
    func modalDidDismiss()
}

class CromiModalViewController: UIViewController {
    
    weak var delegate: CromiModalDelegate?

    @IBOutlet private var backgroundBlur: UIVisualEffectView!
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet var buttonRow: ButtonRow!
    var contentView = UIView() {
        didSet {
            for view in scrollView.subviews {
                view.removeFromSuperview()
            }
            scrollView.addSubview(contentView)
        }
    }
    
    init() {
        super.init(nibName: "CromiModalViewController", bundle: nil)
        view.alpha = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundBlur.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        contentView.frame.size.width = scrollView.bounds.width
        contentView.frame.size.height = contentView.intrinsicContentSize.height
        scrollView.contentInset.top = scrollView.bounds.height > contentView.intrinsicContentSize.height ? scrollView.bounds.height - contentView.intrinsicContentSize.height : 0
    }
    
    // MARK: - Presentation
    private var hiddenScrollViewYOffset: CGFloat {
        return min(contentView.intrinsicContentSize.height, scrollView.bounds.height) + 80
    }
    
    func present(on parentVC: UIViewController) {
        backgroundBlur.effect = nil
        parentVC.addChildViewController(self)
        parentVC.view.addSubview(view)
        
        scrollView.transform = CGAffineTransform(translationX: 0, y: hiddenScrollViewYOffset)
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.backgroundBlur.effect = UIBlurEffect(style: .light)
            self.scrollView.transform = CGAffineTransform.identity
        }, completion: nil)
        buttonRow.present()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        delegate?.modalWillDismiss()
        buttonRow.dismiss()
        
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.backgroundBlur.effect = nil
            self.scrollView.transform = CGAffineTransform(translationX: 0, y: self.hiddenScrollViewYOffset)
        }) { finished in
            self.delegate?.modalDidDismiss()
            self.removeFromParentViewController()
            self.view.removeFromSuperview()
            self.scrollView.transform = CGAffineTransform.identity
        }
    }

}
