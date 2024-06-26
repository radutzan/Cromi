//
//  StreetSignView.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/8/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import RaduKit

struct SignConstants {
    static var cornerRadius: CGFloat = 8
}

protocol SignViewDelegate: AnyObject {
    func signViewHeaderTapped(_ signView: SignView)
}

class SignView: NibLoadingView {
    weak var delegate: SignViewDelegate?
    
    @IBOutlet private var headerViewContainer: TappableView!
    @IBOutlet private var contentScrollView: UIScrollView!
    @IBOutlet private var contentViewContainer: UIView!
    private let maskingView = UIView()
    
    override var nibName: String {
        return "SignView"
    }
    var headerView: UIView? {
        didSet {
            setUp(containerView: headerViewContainer, with: headerView)
        }
    }
    var contentView: UIView? {
        didSet {
            setUp(containerView: contentViewContainer, with: contentView)
        }
    }
    
    // MARK: - Setup
    override func didLoadNibView() {
        apply(shadow: .floatingMed)
        
        view.layer.cornerRadius = SignConstants.cornerRadius
        view.layer.masksToBounds = true
        
        maskingView.frame = CGRect(size: .zero, center: .zero)
        maskingView.backgroundColor = .blue
        view.mask = maskingView
//        addSubview(maskingView) // masking debug
        
        headerViewContainer.tapAction = { view in
            self.delegate?.signViewHeaderTapped(self)
        }
    }
    
    // TouchTransparentView
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isVisible {
            maskingView.frame.size = bounds.size
        }
    }
    
    // MARK: - Presentation
    private var maskViewCenter: CGPoint {
        return maskViewCenter(for: CGPoint(x: 0.5, y: 0.5))
    }
    
    private func maskViewCenter(for relativePoint: CGPoint) -> CGPoint {
        return CGPoint(x: frame.width * relativePoint.x, y: frame.height  * relativePoint.y)
    }
    
    private(set) var isVisible = false
    func present(originSize: CGSize, translationX: CGFloat, cornerRadius: CGFloat, bottomOffset: CGFloat) {
        willAppear()
        
        maskingView.frame.size = originSize
        maskingView.center = maskViewCenter
        maskingView.layer.cornerRadius = min(min(originSize.width, originSize.height) / 2, cornerRadius)
        alpha = 0.8
        view.transform = CGAffineTransform(translationX: translationX, y: (bounds.height + originSize.height) / 2 + bottomOffset)
        
        let animator = UIViewPropertyAnimator(duration: 0.54, dampingRatio: 0.8) {
            self.alpha = 1
            self.view.transform = .identity
            self.maskingView.frame.size = self.bounds.size
            self.maskingView.center = self.maskViewCenter
            self.maskingView.layer.cornerRadius = SignConstants.cornerRadius
        }
        animator.addCompletion { (position) in
            if self.contentScrollView.contentSize.height > self.contentScrollView.bounds.height {
                self.contentScrollView.flashScrollIndicators()
            }
        }
        animator.startAnimation()
    }
    
    func dismiss(targetSize: CGSize, translationX: CGFloat, cornerRadius: CGFloat, bottomOffset: CGFloat) {
        willDisappear()
        
        delay(1/60) {
            if self.isVisible { return }
            let animator = UIViewPropertyAnimator(duration: 0.36, dampingRatio: 1) {
                self.alpha = 0
                self.view.transform = CGAffineTransform(translationX: translationX, y: (self.bounds.height + targetSize.height) / 2 + bottomOffset)
                self.maskingView.frame.size = targetSize
                self.maskingView.center = self.maskViewCenter
                self.maskingView.layer.cornerRadius = min(min(targetSize.width, targetSize.height) / 2, cornerRadius)
            }
            animator.addCompletion { (position) in
                self.view.transform = .identity
            }
            animator.startAnimation()
        }
    }
    
    func willAppear() {
        isVisible = true
        isUserInteractionEnabled = true
    }
    
    func willDisappear() {
        isVisible = false
        isUserInteractionEnabled = false
    }
}
