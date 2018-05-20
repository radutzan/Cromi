//
//  CromiDialogViewController.swift
//
//  Created by Radu Dutzan on 1/9/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import RaduKit

class ForkModalViewController: AbstractModalViewController, UIScrollViewDelegate {

    @IBOutlet private var backgroundBlur: UIVisualEffectView!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var containerViewVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet private var contentStackView: UIStackView!
    @IBOutlet private var headerView: ForkModalHeaderView!
    @IBOutlet private var contentScrollView: UIScrollView!
    @IBOutlet private var contentViewContainer: UIView!
    @IBOutlet private var waitingStageView: UIView!
    @IBOutlet private var waitingStageActivityIndicator: UIActivityIndicatorView!
    private let scrollShadowView = UIView()
    override var title: String? {
        didSet {
            headerView.title = title ?? ""
        }
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    var contentView: UIView {
        didSet {
            setUpContentView()
        }
    }
    var contentViewContainerMargins: UIEdgeInsets {
        get {
            return contentViewContainer.layoutMargins
        }
        set {
            contentViewContainer.layoutMargins = newValue
        }
    }
    /// Setting this to false will cause the modal to remain in a 'loading' state after submitting. Calling `dismiss(with:)` becomes a responsibility of the subclass.
    var dismissesOnSubmit: Bool = true
    var submitAction: (() ->())?
    var dismissAction: ((InteractionResult) ->())?
    var isSubmitEnabled: Bool = true {
        didSet {
            headerView.submitButton.isEnabled = isSubmitEnabled && !isWaiting
        }
    }
    var submitButtonTitle: String = "Aceptar" {
        didSet {
            headerView.submitButton.setTitle(submitButtonTitle, for: .normal)
        }
    }
    /// Setting this to false will cause the modal to remain visible after tapping the Cancel button. Calling `dismiss(with:)` becomes a responsibility of the subclass.
    var dismissesOnCancel: Bool = true
    var cancelAction: (() ->())?
    var isCancelVisible: Bool = true {
        didSet {
            headerView.cancelButton.isHidden = !isCancelVisible
            headerView.titleLabel.textAlignment = isCancelVisible ? .center : .left
            headerView.view.layoutMargins.left = isCancelVisible ? 12 : 24
        }
    }
    var cancelButtonTitle: String = "Cancelar" {
        didSet {
            headerView.cancelButton.setTitle(cancelButtonTitle, for: .normal)
        }
    }
    
    // MARK: - Setup
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.contentView = UIView()
        super.init(nibName: "ForkModalViewController", bundle: nibBundleOrNil)
        commonInit()
    }
    
    init(contentView: UIView) {
        self.contentView = contentView
        super.init(nibName: "ForkModalViewController", bundle: nil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.contentView = UIView()
        super.init(nibName: "ForkModalViewController", bundle: nil)
        commonInit()
    }
    
    private func commonInit() {
        self.view.alpha = 1
        contentScrollView.delegate = self
        setUpContentView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setUpContentView() {
        let transitionDuration: TimeInterval = 0.24
        UIView.transition(with: contentViewContainer, duration: transitionDuration, options: .transitionCrossDissolve, animations: {
            for view in self.contentViewContainer.subviews {
                view.removeFromSuperview()
            }
            self.contentViewContainer.addSubview(self.contentView)
            self.contentView.generateConstraintsToFillSuperview(relativeToMargins: true)
        }, completion: nil)
        let animator = UIViewPropertyAnimator(duration: transitionDuration, dampingRatio: 1) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillChangeFrame, object: nil, queue: nil) { (notification) in
            guard let userInfo = notification.userInfo else { return }
            self.updateForKeyboard(with: userInfo)
        }
        
        headerView.cancelButton.tapAction = { _ in
            if self.dismissesOnCancel {
                self.dismiss(with: .cancelled)
            }
            self.cancelAction?()
        }
        headerView.submitButton.tapAction = { _ in
            if self.dismissesOnSubmit {
                self.dismiss(with: .success)
            } else {
                self.toggleWaitingState(on: true)
            }
            self.submitAction?()
        }
        
        contentScrollView.addSubview(scrollShadowView)
        scrollShadowView.frame.size.height = 50
        scrollShadowView.frame.origin.y = -50
        scrollShadowView.backgroundColor = .white
        scrollShadowView.alpha = 0
        scrollShadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        scrollShadowView.layer.shadowRadius = 5
        scrollShadowView.layer.shadowOpacity = 0.1
        
        containerView.layer.backgroundColor = UIColor.white.cgColor
        containerView.layer.cornerRadius = CornerRadius.container
        containerView.clipsToBounds = true
        backgroundBlur.contentView.apply(shadow: .floatingHigh)
    }
    
    override func viewWillLayoutSubviews() {
        scrollShadowView.frame.size.width = containerView.bounds.width
    }
    
    // MARK: - Pushing another modal
    override func modalWillPresent(modal: AbstractModalViewController) {
        guard modal is ForkModalViewController else { return }
        toggleIsBeingPushed(to: true)
    }
    
    override func modalWillDismiss(modal: AbstractModalViewController) {
        guard modal is ForkModalViewController else { return }
        toggleIsBeingPushed(to: false)
    }
    
    private func toggleIsBeingPushed(to pushed: Bool) {
        let animator = UIViewPropertyAnimator(duration: 0.58, dampingRatio: 1) {
            self.containerView.transform = pushed ? CGAffineTransform(translationX: -self.view.bounds.width * 1.25, y: 0) : .identity
        }
        animator.startAnimation()
    }
    
    // MARK: - Presenting/dismissing
    override func present(on parentVC: ModalSupportingViewController, completion: (() -> ())? = nil) {
        super.present(on: parentVC)
        
        let isPush = parentVC is ForkModalViewController
        
        backgroundBlur.effect = nil
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        containerView.transform = CGAffineTransform(rotationAngle: -1).concatenating(CGAffineTransform(translationX: view.bounds.width, y: -view.bounds.height / 2))
        
        let animator = UIViewPropertyAnimator(duration: 0.64, dampingRatio: 0.86) {
            self.setNeedsStatusBarAppearanceUpdate()
            if !isPush { self.backgroundBlur.effect = UIBlurEffect(style: .dark) }
            self.containerView.transform = .identity
        }
        animator.addCompletion { (position) in
            self.presentationCompletionActions(self)
        }
        animator.startAnimation()
    }
    
    enum InteractionResult {
        case success, cancelled
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismiss(with: .cancelled)
    }
    
    func dismiss(with result: InteractionResult) {
        delegate?.modalWillDismiss(modal: self)
        
        let isPop = parent is ForkModalViewController
        
        let transformXOffset = isPop ? view.bounds.width + 128 : 128
        let transformYOffset = (view.bounds.height + containerView.bounds.height) / 2 + 100
        let targetTransform = result == .cancelled ? CGAffineTransform(rotationAngle: 1).concatenating(CGAffineTransform(translationX: transformXOffset, y: transformYOffset)) : CGAffineTransform(rotationAngle: -0.5).concatenating(CGAffineTransform(translationX: transformXOffset, y: -transformYOffset))
        dismissAction?(result)
        
        let animator = UIViewPropertyAnimator(duration: 0.58, dampingRatio: 1) {
            self.view.endEditing(true)
            self.setNeedsStatusBarAppearanceUpdate()
            self.backgroundBlur.effect = nil
            self.containerView.transform = targetTransform
        }
        animator.addCompletion { (position) in
            self.contentView.removeFromSuperview()
            self.dismissalCompletionActions(self)
        }
        animator.startAnimation()
    }
    
    // MARK: - Waiting state
    private var isWaiting = false
    func toggleWaitingState(on: Bool) {
        guard on != isWaiting else { return }
        isWaiting = on
        headerView.submitButton.isEnabled = on ? false : isSubmitEnabled
        if on {
            waitingStageView.isHidden = false
            waitingStageActivityIndicator.startAnimating()
        }
        let animator = UIViewPropertyAnimator(duration: 0.36, dampingRatio: 1) {
            self.waitingStageView.alpha = on ? 1 : 0
        }
        animator.addCompletion { (position) in
            if !on {
                self.waitingStageView.isHidden = true
                self.waitingStageActivityIndicator.stopAnimating()
            }
        }
        animator.startAnimation()
    }
    
    // MARK: - Displacement
    private var isShowingKeyboard = false
    private func updateForKeyboard(with userInfo: [AnyHashable: Any]) {
        guard let frame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        let effectiveHeight = view.bounds.height - frame.minY
        isShowingKeyboard = effectiveHeight != 0
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0, options: UIViewAnimationOptions(rawValue: animationCurve.uintValue), animations: {
            self.containerViewVerticalCenterConstraint.constant = -effectiveHeight / 2
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func offsetVertically(by height: CGFloat, animated: Bool = true) {
        guard !isShowingKeyboard else { return }
        let animator = UIViewPropertyAnimator(duration: animated ? 0.42 : 0, dampingRatio: 1) {
            self.containerViewVerticalCenterConstraint.constant = height
            self.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    // MARK: - Scrolling
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollShadowView.frame.origin.y = -scrollShadowView.bounds.height + scrollView.contentOffset.y
        toggleScrollSeparator(on: scrollView.contentOffset.y > 0)
    }
    
    private var isScrollSeparatorVisible = false
    private func toggleScrollSeparator(on: Bool) {
        guard on != isScrollSeparatorVisible else { return }
        isScrollSeparatorVisible = on
        let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut) {
            self.scrollShadowView.alpha = on ? 1 : 0
        }
        animator.startAnimation()
    }
}
