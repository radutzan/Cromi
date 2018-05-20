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
//        addSubview(maskerView) // masking debug
        
        headerViewContainer.tapAction = { view in
            self.delegate?.signViewHeaderTapped(self)
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
//        alpha = isVisible ? 1 : 0
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
        return CGPoint(x: frame.width / 2, y: frame.height / 2)
    }
    
    private(set) var isVisible = false
    func present(originSize: CGSize, bottomOffset: CGFloat) {
        willAppear()
//        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: (bounds.height + originSize.height) / 2 + bottomOffset)
        maskingView.frame.size = originSize
        maskingView.center = maskViewCenter
        maskingView.layer.cornerRadius = min(originSize.width, originSize.height) / 2
        
        let animator = UIViewPropertyAnimator(duration: 0.54, dampingRatio: 0.8) {
            self.alpha = 1
            self.transform = .identity
            self.maskingView.frame.size = self.bounds.size
            self.maskingView.center = self.maskViewCenter
            self.maskingView.layer.cornerRadius = SignConstants.cornerRadius
        }
        animator.startAnimation()
    }
    
    func dismiss(targetSize: CGSize, bottomOffset: CGFloat) {
        willDisappear()
        
        delay(1/60) {
            if self.isVisible { return }
            UIView.animateKeyframes(withDuration: 0.36, delay: 0, options: [.calculationModeCubic], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.7, animations: {
                    self.alpha = 0
                })
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    self.transform = CGAffineTransform(translationX: 0, y: (self.bounds.height + targetSize.height) / 2 + bottomOffset)
                    self.maskingView.frame.size = targetSize
                    self.maskingView.center = self.maskViewCenter
                    self.maskingView.layer.cornerRadius = min(targetSize.width, targetSize.height) / 2
                })
            }, completion: nil)
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
