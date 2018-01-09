//
//  BipEntryView.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/4/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class BipEntryView: NibLoadingView, UITextFieldDelegate {

    @IBOutlet private var entryView: UIView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var numberField: UITextField!
    @IBOutlet private var nameField: UITextField!
    @IBOutlet private var colorSelectionArea: UIView!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var addButton: UIButton!
    var addAction: ((Int, String, UIColor) -> ())?
    var cancelAction: (() -> ())?
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    override func becomeFirstResponder() -> Bool {
        return numberField.becomeFirstResponder()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 280, height: entryView.bounds.height)
    }
    
    override func didLoadNibView() {
        titleLabel.text = NSLocalizedString("Add Card Title", comment: "")
        numberField.placeholder = NSLocalizedString("Card Number Placeholder", comment: "")
        numberField.delegate = self
        nameField.placeholder = NSLocalizedString("Card Name Placeholder", comment: "")
        nameField.delegate = self
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        cancelButton.tapAction = { _ in
            self.endEditing(true)
            self.cancelAction?()
        }
        addButton.setTitle(NSLocalizedString("Add", comment: ""), for: .normal)
        addButton.isEnabled = false
        addButton.tapAction = { _ in
            guard let numberText = self.numberField.text, let number = Int(numberText) else { return }
            guard let title = self.nameField.text else {
                print("BipEntryView: Attempted to complete without name")
                let alert = UIAlertController(title: "NO NAME TITLE", message: "NO NAME MESSAGE", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OKAY", style: .default, handler: { _ in
                    self.nameField.becomeFirstResponder()
                }))
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                return
            }
            self.addAction?(number, title, .blue)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == numberField {
            nameField.becomeFirstResponder()
        } else if textField == nameField {
            view.endEditing(true)
        }
        return true
    }
    
    private var isCardValid = false {
        didSet {
            if (nameField.text?.count ?? 0) > 0 && isCardValid { addButton.isEnabled = true }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField == numberField else { return }
        guard let numberText = textField.text, let number = Int(numberText) else { return }
        BipCard.isCardValid(id: number) { (result, error) in
            mainThread {
                if let result = result {
                    if !result {
                        print("BipEntryView: Card is invalid")
                        let alert = UIAlertController(title: "INVALID CARD TITLE", message: "INVALID CARD MESSAGE", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "RETRY", style: .default, handler: { _ in
                            self.numberField.becomeFirstResponder()
                        }))
                        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                    } else {
                        self.isCardValid = true
                    }
                } else {
                    print("BipEntryView: Card validity check error")
                    // error
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == numberField {
            if !string.isNumeric { return false }
        } else if textField == nameField, let text = textField.text as NSString?  {
            let finalString = text.replacingCharacters(in: range, with: string)
            let shouldEnable = finalString.count > 0 && isCardValid
            if addButton.isEnabled != shouldEnable { addButton.isEnabled = shouldEnable }
        }
        return true
    }

}
