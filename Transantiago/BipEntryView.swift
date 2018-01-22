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
    @IBOutlet private var cardView: UIView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var numberField: UITextField!
    @IBOutlet private var nameField: UITextField!
    @IBOutlet private var colorSelectionArea: UIView!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var addButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    private var colorOptionPicker: ColorOptionPickerView!
    private var isEditing = false
    private var isVisible = true
    var addAction: ((Int, String, UIColor) -> ())?
    var cancelAction: (() -> ())?
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    override func becomeFirstResponder() -> Bool {
        return nameField.becomeFirstResponder()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 280, height: entryView.bounds.height)
    }
    
    private var isAddingEnabled: Bool = false {
        didSet {
            addButton.isEnabled = isAddingEnabled
            if addButton.isHidden && isAddingEnabled {
                addButton.isHidden = false
                activityIndicator.isHidden = true
            }
        }
    }
    private var isValidatingCardNumber = false {
        didSet {
            addButton.isHidden = isValidatingCardNumber
            activityIndicator.isHidden = !isValidatingCardNumber
            if isValidatingCardNumber {
                activityIndicator.startAnimating()
            }
        }
    }
    
    override func didLoadNibView() {
        titleLabel.text = NSLocalizedString("Add Card Title", comment: "")
        setUpFields()
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        cancelButton.tapAction = { _ in
            self.isVisible = false
            self.endEditing(true)
            self.cancelAction?()
        }
        isAddingEnabled = false
        addButton.setTitle(NSLocalizedString("Add", comment: ""), for: .normal)
        addButton.tapAction = { _ in
            guard self.finishEditing() else { return }
        }
        activityIndicator.isHidden = true
        
        let colorOptions = [ColorOption(localizedName: "Verde", color: UIColor(hexString: "1FCF5A")),
                            ColorOption(localizedName: "Amarillo", color: UIColor(hexString: "FFCC00")),
                            ColorOption(localizedName: "Naranjo", color: UIColor(hexString: "FF8800")),
                            ColorOption(localizedName: "Frutilla", color: UIColor(hexString: "FF2D55")),
                            ColorOption(localizedName: "Morado", color: UIColor(hexString: "5B54E8")),
                            ColorOption(localizedName: "Azul", color: UIColor(hexString: "007AFF"))]
        colorOptionPicker = ColorOptionPickerView(options: colorOptions)
        colorOptionPicker.selectedIndex = 5
        colorOptionPicker.optionSpacing = 6
        colorOptionPicker.frame = colorSelectionArea.bounds
        colorOptionPicker.optionChangeAction = { option in
            let isLight = option.color.isLight()
            let textColor: UIColor = isLight ? .black : .white
            UIView.animate(withDuration: 0.2, animations: {
                self.cardView.backgroundColor = option.color
                self.setUpFields(textColor: textColor)
            })
        }
        colorOptionPicker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        colorSelectionArea.addSubview(colorOptionPicker)
    }
    
    private func setUpFields(textColor: UIColor = .white) {
        let secondaryOpacity: CGFloat = 0.66
        let placeholderTextColor = textColor.withAlphaComponent(secondaryOpacity)
        let fieldBackgroundColor = textColor.withAlphaComponent(textColor == .white ? 0.16 : 0.08)
        
        nameField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Card Name Placeholder", comment: ""), attributes: [.foregroundColor: placeholderTextColor])
        nameField.delegate = self
        nameField.backgroundColor = fieldBackgroundColor
        nameField.textColor = textColor
        nameField.tintColor = textColor
        
        let numberFont = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .regular)
        numberField.font = numberFont
        numberField.attributedPlaceholder = NSAttributedString(string: "00000000", attributes: [.foregroundColor: placeholderTextColor, .font: numberFont])
        numberField.delegate = self
        numberField.alpha = isEditing ? secondaryOpacity : 1
        numberField.backgroundColor = isEditing ? .clear : fieldBackgroundColor
        numberField.textColor = textColor
        numberField.tintColor = textColor
        
        cardView.layoutMargins.bottom = isEditing ? 4 : 12
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func editWith(number: Int, name: String, color: UIColor, completion: (() -> ())? = nil) {
        isEditing = true
        currentCardNumber = number
        didValidateCurrentCardNumber = true
        isCurrentCardNumberValid = true
        
        titleLabel.text = NSLocalizedString("Edit Card Title", comment: "")
        numberField.text = String(number)
        numberField.isEnabled = false
        numberField.textColor = UIColor.black.withAlphaComponent(0.5)
        nameField.text = name
        
        var didSelectColorOption = false
        for (index, option) in colorOptionPicker.options.enumerated() {
            if option.color.description == color.description {
                colorOptionPicker.selectedIndex = index
                didSelectColorOption = true
                break
            }
        }
        if !didSelectColorOption {
            colorOptionPicker.selectedIndex = 5
        }
        
        isAddingEnabled = true
        addButton.setTitle(NSLocalizedString("Save", comment: ""), for: .normal)
        addButton.tapAction = { _ in
            guard self.finishEditing() else { return }
            completion?()
        }
    }
    
    @discardableResult private func finishEditing() -> Bool {
        guard let validated = self.validateInputs() else { return false }
        self.endEditing(true)
        self.addAction?(validated.number, validated.name, self.colorOptionPicker.selectedOption.color)
        return true
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
        let storedNumbers = User.current.bipCards.map { $0.id }
        if storedNumbers.contains(currentCardNumber) && !isEditing {
            print("BipEntryView: Attempted to add already added card")
            let alert = UIAlertController(title: NSLocalizedString("Card Already Added Alert Title", comment: ""), message: NSLocalizedString("Card Already Added Alert Message", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { _ in
                self.numberField.becomeFirstResponder()
            }))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            return nil
        }
        return (currentCardNumber, name)
    }
    
    // MARK: - Card number validation
    private var isCurrentCardNumberValid = false {
        didSet {
            isAddingEnabled = (nameField.text?.count ?? 0) > 0 && isCurrentCardNumberValid
        }
    }
    
    private var didValidateCurrentCardNumber = false
    private var currentCardNumber: Int = 0 {
        didSet {
            guard oldValue != currentCardNumber else { return }
            didValidateCurrentCardNumber = false
            isCurrentCardNumberValid = false
        }
    }
    
    private func validate(cardNumber number: Int, silently: Bool = false) {
        guard number == currentCardNumber else {
            validate(cardNumber: currentCardNumber, silently: silently)
            return
        }
        
        if String(currentCardNumber).count > 8 {
            isCurrentCardNumberValid = false
            didValidateCurrentCardNumber = true
            return
        }
        
        guard !didValidateCurrentCardNumber else { return }//, !isValidatingCardNumber else { return }
        isValidatingCardNumber = true
        
        BipCard.isCardValid(id: number) { (result, error) in
            mainThread {
                guard self.isVisible else { return }
                self.isValidatingCardNumber = false
                guard number == self.currentCardNumber else {
//                    self.validate(cardNumber: self.currentCardNumber, silently: silently)
                    return
                }
                if let isValid = result {
                    self.didValidateCurrentCardNumber = true
                    if isValid {
                        print("BipEntryView: Card is valid")
                        self.isCurrentCardNumberValid = true
                    } else {
                        print("BipEntryView: Card is invalid")
                        guard !silently else { return }
                        let alert = UIAlertController(title: NSLocalizedString("Invalid Bip Card Alert Title", comment: ""), message: NSLocalizedString("Invalid Bip Card Alert Message", comment: ""), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: ""), style: .default, handler: { _ in
                            self.numberField.becomeFirstResponder()
                        }))
                        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                    }
                } else {
                    print("BipEntryView: Card validity check error")
                    guard !silently else { return }
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
            if finalString.count > 8 { return false }
            guard let number = Int(finalString) else { return false }
            currentCardNumber = number
            if finalString.count >= 7 { validate(cardNumber: number, silently: true) }
        } else if textField == nameField {
            let shouldEnable = finalString.count > 0 && isCurrentCardNumberValid
            if isAddingEnabled != shouldEnable { isAddingEnabled = shouldEnable }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameField {
            numberField.becomeFirstResponder()
        } else if textField == numberField {
            finishEditing()
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField == numberField else { return }
        guard let numberText = textField.text, let number = Int(numberText) else { return }
        validate(cardNumber: number)
    }

}
