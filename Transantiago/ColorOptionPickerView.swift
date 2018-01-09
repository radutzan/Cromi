//
//  ColorOptionPickerView.swift
//
//  Created by Radu Dutzan on 1/9/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

struct ColorOption {
    var localizedName: String
    var color: UIColor
}

class ColorOptionPickerView: UIView {
    var optionChangeAction: ((ColorOption) -> ())?
    
    var options: [ColorOption] {
        didSet {
            setUpOptionViews()
        }
    }
    var selectedIndex: Int = 0 {
        didSet {
            for (index, view) in optionViews.enumerated() {
                view.isSelected = selectedIndex == index
            }
        }
    }
    var selectedOption: ColorOption {
        return selectedIndex > options.count ? options[0] : options[selectedIndex]
    }
    var optionSize: CGFloat = 32 {
        didSet {
            layoutOptionViews()
        }
    }
    var optionSpacing: CGFloat = 12 {
        didSet {
            layoutOptionViews()
        }
    }
    private var optionViews: [ColorOptionView] = []
    private let optionContainer = UIView()
    
    override var frame: CGRect {
        didSet {
            optionContainer.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        }
    }
    
    init(options: [ColorOption]) {
        self.options = options
        super.init(frame: CGRect.zero)
        setUpOptionViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        addSubview(optionContainer)
    }
    
    private func setUpOptionViews() {
        for subview in optionContainer.subviews {
            subview.removeFromSuperview()
        }
        optionViews = []
        
        guard options.count > 0 else { return }
        
        for (index, option) in options.enumerated() {
            let colorOptionView = ColorOptionView()
            colorOptionView.color = option.color
            colorOptionView.isSelected = selectedIndex == index
            optionContainer.addSubview(colorOptionView)
            optionViews.append(colorOptionView)
            colorOptionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(option(tapped:))))
        }
        layoutOptionViews()
    }
    
    private func layoutOptionViews() {
        for (index, optionView) in optionViews.enumerated() {
            optionView.frame.size = CGSize(width: optionSize, height: optionSize)
            optionView.frame.origin.x = (optionSize + optionSpacing) * CGFloat(index)
        }
        
        optionContainer.frame = CGRect(x: 0, y: 0, width: optionViews.last?.frame.maxX ?? 0, height: optionSize)
    }
    
    @objc private func option(tapped tap: UITapGestureRecognizer) {
        guard let optionView = tap.view as? ColorOptionView, let selectedIndex = optionViews.index(of: optionView) else { return }
        self.selectedIndex = selectedIndex
        optionChangeAction?(selectedOption)
    }
}

class ColorOptionView: UIView {
    var isSelected = false {
        didSet {
            selectionIndicatorLayer.isHidden = !isSelected
        }
    }
    var color: UIColor = UIColor.black {
        didSet {
            selectionIndicatorLayer.borderColor = color.cgColor
            colorLayer.backgroundColor = color.cgColor
        }
    }
    
    private let selectionIndicatorLayer = CALayer()
    private let colorLayer = CALayer()
    
    override func layoutSubviews() {
        colorLayer.frame = bounds.insetBy(dx: 4, dy: 4)
        colorLayer.cornerRadius = colorLayer.bounds.height / 2
        selectionIndicatorLayer.frame = bounds
        selectionIndicatorLayer.cornerRadius = bounds.height / 2
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        colorLayer.backgroundColor = color.cgColor
        layer.addSublayer(colorLayer)
        
        selectionIndicatorLayer.borderWidth = 2
        selectionIndicatorLayer.borderColor = color.cgColor
        selectionIndicatorLayer.isHidden = !isSelected
        layer.addSublayer(selectionIndicatorLayer)
    }
}
