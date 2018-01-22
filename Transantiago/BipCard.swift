//
//  BipCard.swift
//  Cromi
//
//  Created by Radu Dutzan on 12/27/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

class BipCard: NSObject, NSCoding {
    
    let id: Int
    var name: String {
        didSet {
            User.current.didUpdateData()
        }
    }
    var color: UIColor {
        didSet {
            User.current.didUpdateData()
        }
    }
    private(set) var lastUpdated: Date? = nil
    private(set) var balance: Int = 0
    enum Kind {
        case normal, student
    }
    var kind: Kind {
        let stringID = String(id)
        if stringID.count == 8 && (stringID.hasPrefix("8") || stringID.hasPrefix("7")) { return .student }
        return .normal
    }
    
    init(id: Int, name: String, color: UIColor) {
        self.id = id
        self.name = name
        self.color = color
        super.init()
        updateBalance()
    }
    
    // MARK: - Coding
    required init?(coder decoder: NSCoder) {
        guard let name = decoder.decodeObject(forKey: "name") as? String,
            let color = decoder.decodeObject(forKey: "color") as? UIColor else { return nil }
        self.id = decoder.decodeInteger(forKey: "id")
        self.name = name
        self.color = color
        self.lastUpdated = decoder.decodeObject(forKey: "lastUpdated") as? Date
        self.balance = decoder.decodeInteger(forKey: "balance")
        super.init()
        updateBalance()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(name, forKey: "name")
        coder.encode(color, forKey: "color")
        coder.encode(lastUpdated, forKey: "lastUpdated")
        coder.encode(balance, forKey: "balance")
    }
    
    // MARK: - Requests
    static func requestURL(for id: Int) -> URL? {
        return URL(string: "http://www.metrosantiago.cl/contents/guia-viajero/includes/consultarTarjeta/\(id)")
    }
    
    static func isCardValid(id: Int, result: @escaping (Bool?, Error?) -> ()) {
        guard let requestURL = BipCard.requestURL(for: id) else { result(nil, nil); return }
        print("BipCard: Checking validity - \(requestURL.absoluteString)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []), let rootData = jsonObject as? [[String: Any]] {
                guard rootData.count > 0, let status = rootData[0]["estado"] as? Int, status == 0 else { result(false, nil); return }
                result(true, nil)
            }
            if let error = error {
                print("BipCard: Validity request failed with error: \(error)")
                result(nil, error)
            }
        }
        task.resume()
    }
    
    func updateBalance() {
        guard let requestURL = BipCard.requestURL(for: id) else { return }
        print("BipCard: Updating balance - \(requestURL.absoluteString)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []), let rootData = jsonObject as? [[String: Any]] {
                guard rootData.count > 1, let status = rootData[0]["estado"] as? Int, status == 0 else { return }
                let cardData = rootData[1]
                guard let balanceString = cardData["saldo"] as? String, let balanceInt = Int(balanceString) else { return }
                self.balance = balanceInt
                if let dateString = cardData["fecha"] as? String {
                    let formatter = DateFormatter()
                    formatter.timeZone = TimeZone(identifier: "America/Santiago")
                    formatter.dateFormat = "dd/MM/yyyy HH:mm"
                    self.lastUpdated = formatter.date(from: dateString)
                } else {
                    self.lastUpdated = nil
                }
            }
            if let error = error {
                print("BipCard: Balance request failed with error: \(error)")
            }
            User.current.didUpdateData()
        }
        task.resume()
    }
}
