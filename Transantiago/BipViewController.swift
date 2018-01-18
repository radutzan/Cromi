//
//  BipViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 1/4/18.
//  Copyright © 2018 Radu Dutzan. All rights reserved.
//

import UIKit

class BipViewController: CromiOverlayViewController, BipCardViewDelegate, UIGestureRecognizerDelegate {
    
    private let listView = BipListView()
    private var cards: [BipCard] = [] {
        didSet {
            buttonRow.setIsEnabled(on: [1], to: cards.count < 5)
        }
    }
    private let formatter = NumberFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.locale = Locale(identifier: "es_CL")
        formatter.numberStyle = .currency
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(forName: User.Notifications.dataUpdated, object: nil, queue: nil) { (notification) in
            self.updateData()
        }
        
        contentView = listView
        buttonRow.buttonItems = [doneButtonItem, ButtonItem(image: #imageLiteral(resourceName: "button add"), title: NSLocalizedString("Add", comment: ""), action: { _ in self.presentEntryView() })]
        updateData(isFirstLoad: true)
    }
    
    // MARK: - Data updating
    private func updateData(isFirstLoad: Bool = false) {
        let oldData = cards
        cards = User.current.bipCards
        print("BipViewController: updateData - oldData.count: \(oldData.count), cards.count: \(cards.count)")
        
        let shouldAnimate = !isFirstLoad
        
        if oldData.count == 0 && cards.count > 0 {
            // initial load or first add
            print("BipViewController: updateData - initial load or first add")
            performFullListReload()
            
        } else if oldData.count == (cards.count - 1) && cards.count > 0 {
            // addition
            performFullListReload() // temp
            print("BipViewController: updateData - addition")
            
        } else if oldData.count == (cards.count + 1) && cards.count > 0 {
            // removal
            print("BipViewController: updateData - removal")
            
        } else if oldData.count == cards.count && cards.count > 0 {
            // data refresh
            print("BipViewController: updateData - data refresh")
            performDataRefresh()
            
        } else if cards.count == 0 {
            // no cards left
            print("BipViewController: updateData - no cards")
            performFullListReload()
        }
    }
    
    private func performFullListReload() {
        print("BipViewController: Performing full list reload")
        if cards.count > 0 {
            var views: [BipCardView] = []
            for card in cards {
                let view = BipCardView()
                view.delegate = self
                view.deleteAction = { (number, _, _) in
                    self.deleteCard(with: number)
                }
                view.editAction = { (number, name, color) in
                    self.presentEntryView(editingData: (number, name, color))
                }
                view.optionsPanRecognizer.delegate = self
                update(cardView: view, with: card)
                views.append(view)
            }
            listView.views = views
        } else {
            let emptyView = EmptyBipView()
            emptyView.button.tapAction = { _ in self.presentEntryView() }
            listView.views = [emptyView]
        }
        listView.infoLabel.text = cards.count > 0 ? NSLocalizedString("Bip Info Label Text", comment: "") : ""
    }
    
    private func performDataRefresh() {
        for view in listView.views {
            guard let cardView = view as? BipCardView else { continue }
            let matchingCards = cards.filter { $0.id == cardView.cardNumber }
            guard matchingCards.count > 0 else { continue }
            let card = matchingCards[0]
            update(cardView: cardView, with: card)
        }
    }
    
    // MARK: - Data display
    private func update(cardView: BipCardView, with card: BipCard) {
        cardView.cardNumber = card.id
        cardView.nameLabel.text = card.name
        cardView.metadataLabel.text = "\(card.id) \(card.kind == .student ? "• \(NSLocalizedString("Student Card", comment: ""))" : "")"
        cardView.balanceLabel.text = formatter.string(from: card.balance as NSNumber) ?? "Error"
        cardView.updatedDateLabel.text = lastUpdatedString(from: card.lastUpdated)
        cardView.color = card.color
    }
    
    private func lastUpdatedString(from date: Date) -> String {
        let hoursAgo = round((Date().timeIntervalSince(date) / 60) / 60)
        if hoursAgo <= 24 {
            return String(format: NSLocalizedString("Hours Ago Format", comment: ""), Int(hoursAgo))//"hace \(Int(hoursAgo)) horas"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Data editing
    private var preventFullRefresh = false
    private func deleteCard(with number: Int) {
        var indexToDelete: Int?
        for (index, card) in User.current.bipCards.enumerated() {
            if card.id == number {
                indexToDelete = index
                break
            }
        }
        guard let index = indexToDelete else { return }
        preventFullRefresh = true
        User.current.bipCards.remove(at: index)
        //        self.view.setNeedsLayout()
        listView.removeView(with: number) {
            //            self.view.layoutIfNeeded()
        }
    }
    
    private func presentEntryView(editingData: (number: Int, name: String, color: UIColor)? = nil) {
        let isEditing = editingData != nil
        let entryView = BipEntryView()
        if let editingData = editingData {
            entryView.editWith(number: editingData.number, name: editingData.name, color: editingData.color)
        }
        
        let dialogController = CromiDialogViewController(dialogView: entryView)
        dialogController.delegate = self
        dialogController.present(on: self)
        if !isEditing { _ = entryView.becomeFirstResponder() }
        
        entryView.cancelAction = {
            dialogController.dismiss(with: .cancelled)
        }
        entryView.addAction = { (number, name, color) in
            dialogController.dismiss(with: .success)
            if !isEditing {
                User.current.bipCards.append(BipCard(id: number, name: name, color: color))
            } else {
                let cardNumbers = User.current.bipCards.map { $0.id }
                if let index = cardNumbers.index(of: number) {
                    User.current.bipCards[index].name = name
                    User.current.bipCards[index].color = color
                    self.optionRevealingBipCardView?.closeOptions()
                }
            }
        }
    }
    
    // MARK: - Card options handling
    private var optionRevealingBipCardView: BipCardView?
    func bipCardViewWillRevealOptions(cardView: BipCardView) {
        optionRevealingBipCardView = cardView
    }
    
    func bipCardViewWillHideOptions(cardView: BipCardView) {
        optionRevealingBipCardView = nil
    }
    
    func bipCardViewTapped(cardView: BipCardView) {
        optionRevealingBipCardView?.closeOptions()
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let cardRecognizer = gestureRecognizer as? UIPanGestureRecognizer, cardRecognizer.view is BipCardView else { return true }
        if let revealingCard = optionRevealingBipCardView, cardRecognizer.view != revealingCard {
            revealingCard.closeOptions()
            return false
        }
        let velocity = cardRecognizer.velocity(in: self.view)
        return abs(velocity.y) < abs(velocity.x)
    }
}
