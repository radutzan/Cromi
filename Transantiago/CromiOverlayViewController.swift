//
//  CromiOverlayViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/9/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class CromiOverlayViewController: CromiModalViewController {
    
    @IBOutlet private var backgroundBlur: UIVisualEffectView!
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet var buttonRow: ButtonRow!
    var doneButtonItem: ButtonItem {
        return ButtonItem(image: #imageLiteral(resourceName: "button done"), title: NSLocalizedString("Done", comment: ""), action: { _ in
            self.close()
        })
    }
    var contentView = UIView() {
        didSet {
            for view in scrollView.subviews {
                view.removeFromSuperview()
            }
            scrollView.addSubview(contentView)
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "CromiOverlayViewController", bundle: nibBundleOrNil)
        view.alpha = 1
    }
    
    init() {
        super.init(nibName: "CromiOverlayViewController", bundle: nil)
        view.alpha = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundBlur.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
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
    
    override func present(on parentVC: UIViewController) {
        super.present(on: parentVC)
        backgroundBlur.effect = nil
        
        scrollView.transform = CGAffineTransform(translationX: 0, y: hiddenScrollViewYOffset)
        UIView.animate(withDuration: 0.52, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 1, options: [], animations: {
            self.presentationActions(self)
            self.backgroundBlur.effect = UIBlurEffect(style: .light)
            self.scrollView.transform = CGAffineTransform.identity
        }) { finished in
            self.presentationCompletionActions(self)
        }
        buttonRow.present()
    }
    
    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        buttonRow.dismiss()
        
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.dismissalActions(self)
            self.backgroundBlur.effect = nil
            self.scrollView.transform = CGAffineTransform(translationX: 0, y: self.hiddenScrollViewYOffset)
        }) { finished in
            self.dismissalCompletionActions(self)
            self.scrollView.transform = CGAffineTransform.identity
        }
    }

}
