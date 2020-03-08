//
//  CromiOverlayViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/9/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import RaduKit

class CromiOverlayViewController: AbstractModalViewController, UIScrollViewDelegate {
    
    @IBOutlet private var backgroundBlur: UIVisualEffectView!
    @IBOutlet private var scrollView: TouchTransparentScrollView!
    @IBOutlet var buttonRow: ButtonRow!
    var doneButtonItem: ButtonItem {
        return ButtonItem(image: #imageLiteral(resourceName: "button done"), title: "Done".localized(), action: { button in
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
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.scrollIndicatorInsets.right = -10
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        contentView.frame.size.width = scrollView.bounds.width
        contentView.frame.size.height = contentView.intrinsicContentSize.height
        scrollView.contentInset.top = scrollView.bounds.height > contentView.intrinsicContentSize.height ? scrollView.bounds.height - contentView.intrinsicContentSize.height : 0
        scrollView.contentSize = contentView.intrinsicContentSize
    }
    
    private func setUpContentView() {
//        let transitionDuration: TimeInterval = 0.24
//        UIView.transition(with: contentViewContainer, duration: transitionDuration, options: .transitionCrossDissolve, animations: {
//            for view in self.contentViewContainer.subviews {
//                view.removeFromSuperview()
//            }
//            self.contentViewContainer.addSubview(self.contentView)
//            self.contentView.generateConstraintsToFillSuperview(relativeToMargins: true)
//        }, completion: nil)
//        let animator = UIViewPropertyAnimator(duration: transitionDuration, dampingRatio: 1) {
//            self.view.setNeedsLayout()
//            self.view.layoutIfNeeded()
//        }
//        animator.startAnimation()
    }
    
    // MARK: - Presentation
    private var hiddenScrollViewYOffset: CGFloat {
        var bottomMargin: CGFloat = 0
        if #available(iOS 11.0, *) {
            bottomMargin = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        return min(contentView.intrinsicContentSize.height, scrollView.bounds.height) + 80 + bottomMargin
    }
    
    override func present(on parentVC: ModalSupportingViewController, completion: (() -> ())? = nil) {
        super.present(on: parentVC)
        backgroundBlur.effect = nil
        
        scrollView.transform = CGAffineTransform(translationX: 0, y: hiddenScrollViewYOffset)
        let presentAnimator = UIViewPropertyAnimator(duration: 0.48, dampingRatio: 0.76) {
            self.presentationActions(self)
            if #available(iOS 13.0, *) {
                self.backgroundBlur.effect = UIBlurEffect(style: .systemMaterial)
            } else {
                self.backgroundBlur.effect = UIBlurEffect(style: .light)
            }
            self.scrollView.transform = CGAffineTransform.identity
        }
        presentAnimator.addCompletion { (position) in
            completion?()
            self.presentationCompletionActions(self)
        }
        presentAnimator.startAnimation()
        buttonRow.present()
    }
    
    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        buttonRow.dismiss()
        
        prepareBackgroundBlurAnimatorIfNeeded()
        backgroundBlurDismissAnimator?.startAnimation()
        let dismissAnimator = UIViewPropertyAnimator(duration: 0.36, dampingRatio: 1) {
            self.dismissalActions(self)
            self.scrollView.transform = CGAffineTransform(translationX: 0, y: self.hiddenScrollViewYOffset)
        }
        dismissAnimator.addCompletion { (position) in
            completion?()
            self.dismissalCompletionActions(self)
            self.scrollView.transform = CGAffineTransform.identity
        }
        dismissAnimator.startAnimation()
    }
    
    private var backgroundBlurDismissAnimator: UIViewPropertyAnimator?
    private func prepareBackgroundBlurAnimatorIfNeeded() {
        guard backgroundBlurDismissAnimator == nil || backgroundBlurDismissAnimator?.state == .inactive else { return }
        backgroundBlurDismissAnimator = UIViewPropertyAnimator(duration: 0.32, dampingRatio: 1) {
            self.backgroundBlur.effect = nil
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
        prepareBackgroundBlurAnimatorIfNeeded()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let dismissThreshold: CGFloat = 58
        let normalizedOffsetY = scrollView.contentOffset.y + scrollView.contentInset.top
        shouldDismissThroughScroll = normalizedOffsetY < -dismissThreshold
        guard !isBeingDismissed else { return }
        guard normalizedOffsetY <= 0 else {
            backgroundBlurDismissAnimator?.fractionComplete = 0
            return
        }
        backgroundBlurDismissAnimator?.fractionComplete = min(normalizedOffsetY / -220, 0.8)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if shouldDismissThroughScroll {
            dismiss(animated: true)
            shouldDismissThroughScroll = false
        }
    }
}
