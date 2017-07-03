//
//  SearchViewController.swift
//  Cromi
//
//  Created by Radu Dutzan on 6/10/17.
//  Copyright © 2017 Radu Dutzan. All rights reserved.
//

import UIKit
import MapKit

class SearchViewController: UIViewController, SearchBarDelegate {
    
    @IBOutlet var overlayView: UIView!
    @IBOutlet var searchBar: SearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
        
        searchBar.delegate = self
    }
    
    @objc private func endEditing() {
        searchBar.endEditing(true)
        searchBar.clear()
    }
    
    func searchBarDidEnterFocus() {
        UIView.animate(withDuration: 0.2) { 
            self.overlayView.alpha = 1
        }
    }
    
    func searchBarDidResignFocus() {
        UIView.animate(withDuration: 0.2) {
            self.overlayView.alpha = 0
        }
    }
    
    func searchBarRequested(searchTerm: String) {
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = searchTerm
        let localSearch = MKLocalSearch(request: searchRequest)
        localSearch.start { (searchResponse, error) in
            guard let response = searchResponse else {
                guard let error = error as? MKError else { return }
                switch error.code {
                case .directionsNotFound:
                    print("Directions not found. Since this is not a directions request, this should never happen.")
                case .placemarkNotFound:
                    print("placemark not found")
                    self.searchBar.becomeFirstResponder()
                case .loadingThrottled:
                    print("loadingThrottled")
                case .serverFailure:
                    print("serverFailure")
                default:
                    print("unknown error")
                }
                return
            }
            
            print(response)
        }
    }

}
