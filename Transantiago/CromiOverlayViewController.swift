//
//  CromiOverlayViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/9/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class CromiOverlayViewController: CromiModalViewController, UIScrollViewDelegate {
    
    @IBOutlet private var backgroundBlur: UIVisualEffectView!
    @IBOutlet private var scrollView: TouchTransparentScrollView!
    @IBOutlet var buttonRow: ButtonRow!
    var doneButtonItem: ButtonItem {
        return ButtonItem(image: #imageLiteral(resourceName: "button done"), title: NSLocalizedString("Done", comment: ""), action: { button in
            button.isSelected = true
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
        scrollView.delegate = self
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
    
    override func present(on parentVC: UIViewController, completion: (() -> ())? = nil) {
        super.present(on: parentVC)
        backgroundBlur.effect = nil
        
        scrollView.transform = CGAffineTransform(translationX: 0, y: hiddenScrollViewYOffset)
        let animator = UIViewPropertyAnimator(duration: 0.48, dampingRatio: 0.76) {
            self.presentationActions(self)
            self.backgroundBlur.effect = UIBlurEffect(style: .light)
            self.scrollView.transform = CGAffineTransform.identity
        }
        animator.addCompletion { (position) in
            completion?()
            self.presentationCompletionActions(self)
        }
        animator.startAnimation()
        buttonRow.present()
    }
    
    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        buttonRow.dismiss()
        
        UIView.animate(withDuration: 0.36, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [], animations: {
            self.dismissalActions(self)
            self.backgroundBlur.effect = nil
            self.scrollView.transform = CGAffineTransform(translationX: 0, y: self.hiddenScrollViewYOffset)
        }) { finished in
            completion?()
            self.dismissalCompletionActions(self)
            self.scrollView.transform = CGAffineTransform.identity
        }
    }
    
    // MARK: - Scroll dismissal
    private var feedbackGenerator = UISelectionFeedbackGenerator()
    private var shouldDismissThroughScroll = false {
        didSet {
            guard !isBeingPresented, !isBeingDismissed else { return }
            guard shouldDismissThroughScroll != oldValue else { return }
            buttonRow.setIsHighlighted(on: [0], to: shouldDismissThroughScroll) // TODO: set to dismiss button dynamically
            feedbackGenerator.selectionChanged()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        feedbackGenerator.prepare()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let dismissThreshold: CGFloat = 58
        let normalizedOffsetY = scrollView.contentOffset.y + scrollView.contentInset.top
        shouldDismissThroughScroll = normalizedOffsetY < -dismissThreshold
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if shouldDismissThroughScroll {
            dismiss(animated: true)
            shouldDismissThroughScroll = false
        }
    }
}
