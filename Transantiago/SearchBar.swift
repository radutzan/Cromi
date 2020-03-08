//
//  SearchBar.swift
//  Cromi
//
//  Created by Radu Dutzan on 6/14/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

protocol SearchBarDelegate: class {
    func searchBarDidEnterFocus()
    func searchBarDidResignFocus()
    func searchBarRequested(searchTerm: String)
}

@IBDesignable class SearchBar: UIView, UITextFieldDelegate {
    
    weak var delegate: SearchBarDelegate?
    
    private var textField = UITextField()
    private var searchIcon = UIImageView(image: #imageLiteral(resourceName: "icon search"))
    private var backgroundView = UIView()

    override func willMove(toSuperview newSuperview: UIView?) {
        layer.cornerRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 3
        
        backgroundView.backgroundColor = .white
        backgroundView.layer.cornerRadius = 8
        backgroundView.layer.masksToBounds = true
        addSubview(backgroundView)
        
        searchIcon.contentMode = .center
        searchIcon.alpha = 0.42
        addSubview(searchIcon)
        
        textField.placeholder = "Search box placeholder".localized()
        textField.font = .title
        textField.delegate = self
        textField.returnKeyType = .search
        textField.clearButtonMode = .whileEditing
        addSubview(textField)
    }
    
    override func layoutSubviews() {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        backgroundView.frame = bounds
        searchIcon.frame = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.height)
        textField.frame = CGRect(x: searchIcon.frame.maxX, y: 0, width: bounds.width - searchIcon.frame.maxX - 10, height: bounds.height)
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    func clear() {
        textField.text = ""
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.searchBarDidEnterFocus()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        delegate?.searchBarDidResignFocus()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        delegate?.searchBarRequested(searchTerm: textField.text ?? "")
        return true
    }

}
