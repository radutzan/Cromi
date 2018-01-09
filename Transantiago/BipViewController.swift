//
//  BipViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/4/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class BipViewController: CromiModalViewController {
    
    private let listView = BipListView()
    private var cards: [BipCard] {
        return User.current.bipCards
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: User.Notifications.dataUpdated, object: nil, queue: nil) { (notification) in
            self.updateData()
        }
        
        contentView = listView
        buttonRow.buttonItems = [ButtonItem(image: #imageLiteral(resourceName: "button add"), title: NSLocalizedString("Add", comment: ""), action: presentEntryView(from:)), doneButtonItem]
        updateData()
    }
    
    private func updateData() {
        if cards.count > 0 {
            var views: [BipCardView] = []
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "es_CL")
            formatter.numberStyle = .currency
            for card in cards {
                let view = BipCardView()
                view.nameLabel.text = card.name
                view.metadataLabel.text = "\(card.id) \(card.kind == .student ? "• \(NSLocalizedString("Student Card", comment: ""))" : "")"
                view.balanceLabel.text = formatter.string(from: card.balance as NSNumber) ?? "Error"
                view.updatedDateLabel.text = lastUpdatedString(from: card.lastUpdated)
                view.color = card.color
                views.append(view)
            }
            listView.views = views
        } else {
            let emptyView = EmptyBipView()
            emptyView.button.tapAction = presentEntryView(from:)
            listView.views = [emptyView]
        }
        listView.infoLabel.text = NSLocalizedString("Bip Info Label Text", comment: "")
    }
    
    private func presentEntryView(from button: UIButton) {
        let entryView = BipEntryView()
        let dialogController = CromiDialogViewController(dialogView: entryView)
        dialogController.present(on: self)
        entryView.becomeFirstResponder()
        
        entryView.cancelAction = {
            dialogController.dismiss(with: .cancelled)
        }
        entryView.addAction = { (number, name, color) in
            dialogController.dismiss(with: .success)
            User.current.bipCards.append(BipCard(id: number, name: name, color: color))
        }
    }
    
    private func lastUpdatedString(from date: Date) -> String {
        let hoursAgo = round((Date().timeIntervalSince(date) / 60) / 60)
        if hoursAgo <= 24 {
            return "hace \(hoursAgo) horas"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

}
