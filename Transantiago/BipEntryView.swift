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
    private var colorOptionPicker: ColorOptionPickerView!
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
            guard let validated = self.validateInputs() else { return }
            self.addAction?(validated.number, validated.name, self.colorOptionPicker.selectedOption.color)
        }
        
        let colorOptions = [ColorOption(localizedName: "Verde", color: UIColor(hexString: "1FCF5A")),
                            ColorOption(localizedName: "Amarillo", color: UIColor(hexString: "FFCC00")),
                            ColorOption(localizedName: "Naranjo", color: UIColor(hexString: "FF8800")),
                            ColorOption(localizedName: "Frutilla", color: UIColor(hexString: "FF2D55")),
                            ColorOption(localizedName: "Morado", color: UIColor(hexString: "5B54E8")),
                            ColorOption(localizedName: "Azul", color: UIColor(hexString: "007AFF"))]
        colorOptionPicker = ColorOptionPickerView(options: colorOptions)
        colorOptionPicker.selectedIndex = 4
        colorOptionPicker.optionSpacing = 6
        colorOptionPicker.frame = colorSelectionArea.bounds
        colorOptionPicker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        colorSelectionArea.addSubview(colorOptionPicker)
    }
    
    func editWith(number: Int, name: String, color: UIColor, completion: (() -> ())?) {
        currentCardNumber = number
        didValidateCurrentCardNumber = true
        isCurrentCardNumberValid = true
        
        titleLabel.text = NSLocalizedString("Edit Card Title", comment: "")
        numberField.text = String(number)
        nameField.text = name
        
        var didSelectColorOption = false
        for (index, option) in colorOptionPicker.options.enumerated() {
            if option.color == color {
                colorOptionPicker.selectedIndex = index
                didSelectColorOption = true
                break
            }
        }
        if !didSelectColorOption {
            colorOptionPicker.selectedIndex = 4
        }
        
        addButton.setTitle(NSLocalizedString("Save", comment: ""), for: .normal)
        addButton.tapAction = { _ in
            guard let validated = self.validateInputs() else { return }
            completion?()
            self.addAction?(validated.number, validated.name, self.colorOptionPicker.selectedOption.color)
        }
    }
    
    private func validateInputs() -> (number: Int, name: String)? {
        guard isCurrentCardNumberValid else { return nil }
        guard let name = self.nameField.text, name.count > 0 else {
            print("BipEntryView: Attempted to complete without name")
            let alert = UIAlertController(title: NSLocalizedString("No Bip Name Alert Title", comment: ""), message: NSLocalizedString("No Bip Name Alert Message", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { _ in
                self.nameField.becomeFirstResponder()
            }))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            return nil
        }
        return (currentCardNumber, name)
    }
    
    // MARK: - Card number validation
    private var isCurrentCardNumberValid = false {
        didSet {
            addButton.isEnabled = (nameField.text?.count ?? 0) > 0 && isCurrentCardNumberValid
        }
    }
    
    private var isValidatingCardNumber = false
    private var didValidateCurrentCardNumber = false
    private var currentCardNumber: Int = 0 {
        didSet {
            guard oldValue != currentCardNumber else { return }
            didValidateCurrentCardNumber = false
            isCurrentCardNumberValid = false
        }
    }
    
    private func validate(cardNumber number: Int, failSilently: Bool = false) {
        currentCardNumber = number
        
        if String(currentCardNumber).count > 8 {
            isCurrentCardNumberValid = false
            didValidateCurrentCardNumber = true
            return
        }
        
        guard !didValidateCurrentCardNumber, !isValidatingCardNumber else { return }
        isValidatingCardNumber = true
        
        BipCard.isCardValid(id: number) { (result, error) in
            mainThread {
                self.isValidatingCardNumber = false
                guard number == self.currentCardNumber else {
                    self.validate(cardNumber: number)
                    return
                }
                if let isValid = result {
                    self.didValidateCurrentCardNumber = true
                    if isValid {
                        print("BipEntryView: Card is valid")
                        self.isCurrentCardNumberValid = true
                    } else {
                        print("BipEntryView: Card is invalid")
                        guard !failSilently else { return }
                        let alert = UIAlertController(title: NSLocalizedString("Invalid Bip Card Alert Title", comment: ""), message: NSLocalizedString("Invalid Bip Card Alert Message", comment: ""), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: ""), style: .default, handler: { _ in
                            self.numberField.becomeFirstResponder()
                        }))
                        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                    }
                } else {
                    print("BipEntryView: Card validity check error")
                    guard !failSilently else { return }
                    let alert = UIAlertController(title: NSLocalizedString("Bip Validity Check Error Alert Title", comment: ""), message: NSLocalizedString("Bip Validity Check Error Alert Message", comment: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { _ in
                    }))
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - Text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text as NSString? else { return false }
        let finalString = text.replacingCharacters(in: range, with: string)
        
        if textField == numberField {
            if string != "" && !string.isNumeric { return false }
            if let number = Int(finalString), finalString.count == 8 { validate(cardNumber: number) }
        } else if textField == nameField {
            let shouldEnable = finalString.count > 0 && isCurrentCardNumberValid
            if addButton.isEnabled != shouldEnable { addButton.isEnabled = shouldEnable }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == numberField {
            nameField.becomeFirstResponder()
        } else if textField == nameField {
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField == numberField else { return }
        guard let numberText = textField.text, let number = Int(numberText) else { return }
        validate(cardNumber: number)
    }

}
