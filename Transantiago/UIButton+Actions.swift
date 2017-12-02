//
//  UIButton+Actions.swift
//  Cromi
//
//  Created by Radu Dutzan on 11/17/16.
//  Copyright © 2016 Radu Dutzan. All rights reserved.
//

import UIKit

typealias ButtonAction = (_ button: UIButton) -> ()

class ButtonActionWrapper: NSObject {
    var action: ButtonAction
    
    init(action: @escaping ButtonAction) {
        self.action = action
    }
}

private struct ButtonActionKeys {
    static var tap = "this is the tap key"
    static var touchDown = "this is the touch down key"
    static var touchLift = "this is the touch lift"
}

extension UIButton {
    var tapAction: ButtonAction? {
        get {
            if let wrapper = objc_getAssociatedObject(self, &ButtonActionKeys.tap) as? ButtonActionWrapper {
                return wrapper.action
            }
            return nil
        }
        set {
            if let anAction = newValue {
                addTarget(self, action: #selector(runTapAction), for: .touchUpInside)
                objc_setAssociatedObject(self, &ButtonActionKeys.tap, ButtonActionWrapper(action: anAction), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else {
                removeTarget(self, action: #selector(runTapAction), for: .touchUpInside)
            }
        }
    }
    
    var touchDownAction: ButtonAction? {
        get {
            if let wrapper = objc_getAssociatedObject(self, &ButtonActionKeys.touchDown) as? ButtonActionWrapper {
                return wrapper.action
            }
            return nil
        }
        set {
            if let anAction = newValue {
                addTarget(self, action: #selector(runTouchDownAction), for: .touchDown)
                objc_setAssociatedObject(self, &ButtonActionKeys.touchDown, ButtonActionWrapper(action: anAction), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else {
                removeTarget(self, action: #selector(runTouchDownAction), for: .touchDown)
            }
        }
    }
    
    var touchLiftAction: ButtonAction? {
        get {
            if let wrapper = objc_getAssociatedObject(self, &ButtonActionKeys.touchLift) as? ButtonActionWrapper {
                return wrapper.action
            }
            return nil
        }
        set {
            if let anAction = newValue {
                addTarget(self, action: #selector(runTouchLiftAction), for: .touchCancel)
                objc_setAssociatedObject(self, &ButtonActionKeys.touchLift, ButtonActionWrapper(action: anAction), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else {
                removeTarget(self, action: #selector(runTouchLiftAction), for: .touchCancel)
            }
        }
    }
    
    @objc func runTapAction() {
        touchLiftAction?(self)
        tapAction?(self)
    }
    
    @objc func runTouchDownAction() {
        touchDownAction?(self)
    }
    
    @objc func runTouchLiftAction() {
        touchLiftAction?(self)
    }
}
