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
    static func isCardValid(id: Int, result: @escaping (Bool?, Error?) -> ()) {
        print("BipCard: Updating balance for \(id)")
        BipAPI.get.data(for: id) { cardData, error in
            if cardData == nil {
                result(false, error)
            } else {
                result(true, error)
            }
        }
    }
    
    func updateBalance() {
        print("BipCard: Updating balance for \(id)")
        BipAPI.get.data(for: id) { cardData, _ in
            guard let cardData = cardData else { return }
            self.balance = cardData.balance
            self.lastUpdated = cardData.lastUpdated
            User.current.didUpdateData()
        }
    }
}

class BipAPI: NSObject {
    static let get = BipAPI()
    
    private enum APIServer: String {
        case metroDead = "http://www.metrosantiago.cl/contents/guia-viajero/includes/consultarTarjeta/"
        case bipServicio = "https://bip-servicio.herokuapp.com/api/v1/solicitudes.json?bip="
        case franciscoCapone = "http://bip.franciscocapone.com/api/getSaldo/"
        case saldoDashBip = "https://saldo-bip.cl/consulta/api/v1/solicitudes.json?bip="
    }
    
    private let currentServer: APIServer = .saldoDashBip
    private let dateFormatter: DateFormatter
    
    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "America/Santiago")
        super.init()
    }
    
    private func requestURL(for id: Int) -> URL? {
        return URL(string: "\(currentServer.rawValue)\(id)")
    }
    
    func data(for number: Int, result: @escaping ((id: Int, balance: Int, lastUpdated: Date?)?, Error?) -> ()) {
        guard let requestURL = requestURL(for: number) else { return }
        print("BipCard: Getting data - \(requestURL.absoluteString)")
        let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            var finalData: (id: Int, balance: Int, lastUpdated: Date?)? = nil
            defer {
                result(finalData, error)
            }
            if let data = data, let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                finalData = self.process(jsonData: jsonObject, cardNumber: number)
            }
            if let error = error {
                print("BipCard: Balance request failed with error: \(error)")
            }
        }
        task.resume()
    }
    
    private func process(jsonData: Any, cardNumber: Int) -> (id: Int, balance: Int, lastUpdated: Date?)? {
        switch currentServer {
        case .metroDead:
            guard let rootData = jsonData as? [[String: Any]], rootData.count > 1 else { return nil }
            let cardData = rootData[1]
            guard let balanceString = cardData["saldo"] as? String, let balanceInt = Int(balanceString) else { return nil }
            var lastUpdated: Date?
            if let dateString = cardData["fecha"] as? String {
                dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
                lastUpdated = dateFormatter.date(from: dateString)
            }
            return (id: cardNumber, balance: balanceInt, lastUpdated: lastUpdated)
            
        case .bipServicio, .saldoDashBip:
            guard let rootData = jsonData as? [String: String],
                let statusString = rootData["estadoContrato"], statusString == "Contrato Activo",
                let idString = rootData["id"],
                let balanceString = rootData["saldoTarjeta"],
                let dateString = rootData["fechaSaldo"] else { return nil }
            let cleanBalanceString = balanceString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ".", with: "")
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            guard let id = Int(idString), let balance = Int(cleanBalanceString), let lastUpdated = dateFormatter.date(from: dateString) else { return nil }
            return (id: id, balance: balance, lastUpdated: lastUpdated)
            
        default:
            return nil
        }
    }
}
