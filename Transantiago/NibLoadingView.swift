// https://gist.github.com/winkelsdorf/16c481f274134718946328b6e2c9a4d8

import UIKit

// Usage: Subclass your UIView from NibLoadView to automatically load a xib with the same name as your class

protocol NibDefinable {
    var nibName: String { get }
}

@IBDesignable
class NibLoadingView: UIView, NibDefinable {

    @IBOutlet weak var view: UIView!

    var nibName: String {
        return String(describing: type(of: self))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
    }

    private func nibSetup() {
        backgroundColor = .clear

        // Nib setup
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        didLoadNibView()
        
        // Font update registering
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateFonts),
                                               name: Notification.Name.UIContentSizeCategoryDidChange,
                                               object: nil)
        updateFonts()
    }

    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let nibView = nib.instantiate(withOwner: self, options: nil).first as! UIView

        return nibView
    }
    
    func didLoadNibView() {}
    
    @objc func updateFonts() {}

}
