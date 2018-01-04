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
        contentView = listView
        buttonRow.buttons = [Button(image: #imageLiteral(resourceName: "button add"), title: NSLocalizedString("Add", comment: ""), action: presentEntryView(from:)),
                             Button(image: #imageLiteral(resourceName: "button done"), title: NSLocalizedString("Done", comment: ""), action: { _ in self.dismiss(animated: true) })]
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
                view.metadataLabel.text = "\(card.id) \(card.kind == .student ? NSLocalizedString("Student Card", comment: "") : "")"
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
    }
    
    private func presentEntryView(from button: UIButton) {
        
    }
    
    private func lastUpdatedString(from date: Date) -> String {
        let hoursAgo = round((date.timeIntervalSinceNow / 60) / 60)
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
