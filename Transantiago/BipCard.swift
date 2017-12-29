//
//  BipCard.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/27/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

class BipCard: NSObject {
    var id: Int
    var name: String
    var color: UIColor
    var balance: Int = 0
    
    init?(id: Int, name: String, color: UIColor) {
        guard BipCard.isCardValid(id: id) else { return nil }
        self.id = id
        self.name = name
        self.color = color
        super.init()
    }
    
    static func isCardValid(id: Int) -> Bool {
        return false
    }
    
    func updateBalance() {
        guard let requestURL = URL(string: "http://www.metrosantiago.cl/contents/guia-viajero/includes/consultarTarjeta/6\(id)") else { return }
        print("BipCard: Updating balance - \(requestURL.absoluteString)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                
            }
            if let error = error {
                print("BipCard: Balance request failed with error: \(error)")
            }
        }
        task.resume()
    }
    
}
