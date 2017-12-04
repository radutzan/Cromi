//
//  SignServiceRowView.swift
//  Cromi
//
//  Created by Radu Dutzan on 4/10/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit

class SignServiceRowView: NibLoadingView {
    
    @IBOutlet var serviceView1: SignServiceView!
    @IBOutlet var serviceView2: SignServiceView!
    
    convenience init(services: [Service]) {
        self.init(frame: CGRect.zero)
        if services.count >= 1 {
            let service = services[0]
            serviceView1.populate(with: service)
        }
        if services.count >= 2 {
            let service = services[1]
            serviceView2.populate(with: service)
        }
        if services.count >= 3 {
            print("SignServiceRowView: Too many services! Only 2 are supported, received \(services.count).")
        }
    }
    
}
