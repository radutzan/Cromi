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
        view.frame = UIScreen.main.bounds
        backgroundBlur.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
        scrollView.clipsToBounds = false
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        contentView.frame.size.width = scrollView.bounds.width
        contentView.frame.size.height = contentView.intrinsicContentSize.height
        scrollView.contentInset.top = scrollView.bounds.height > contentView.intrinsicContentSize.height ? scrollView.bounds.height - contentView.intrinsicContentSize.height : 0
    }
    
    // MARK: - Presentation
    private var hiddenScrollViewYOffset: CGFloat {
        var bottomMargin: CGFloat = 0
        if #available(iOS 11.0, *) {
            bottomMargin = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        return min(contentView.intrinsicContentSize.height, scrollView.bounds.height) + 80 + bottomMargin
    }
    
    func present(on parentVC: UIViewController) {
        backgroundBlur.effect = nil
        parentVC.addChildViewController(self)
        parentVC.view.addSubview(view)
        
//        view.heightAnchor.constraint(equalTo: parentVC.view.heightAnchor, multiplier: 1).isActive = true
//        view.widthAnchor.constraint(equalTo: parentVC.view.widthAnchor, multiplier: 1).isActive = true
//        view.setNeedsLayout()
//        view.layoutIfNeeded()
        
        scrollView.transform = CGAffineTransform(translationX: 0, y: hiddenScrollViewYOffset)
        UIView.animate(withDuration: 0.52, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 1, options: [], animations: {
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
            self.scrollView.transform = CGAffineTransform.identity
//            for constraint in self.view.constraints {
//                self.view.removeConstraint(constraint)
//            }
            self.removeFromParentViewController()
            self.view.removeFromSuperview()
        }
    }

}
