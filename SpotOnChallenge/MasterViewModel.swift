//
//  MasterViewModel.swift
//  SpotOnChallenge
//
//  Created by Eladio Alvarez Valle on 5/2/19.
//  Copyright © 2019 Eladio Alvarez Valle. All rights reserved.
//

import Foundation

class MasterModelView {
    
    private var data : [Restaurant] = [] {
        
        didSet {
            
            delegate.updateData()
        }
    }
    
    private var delegate : ModelToView
    
    init(delegate : ModelToView) {
        
        self.delegate = delegate
    }
    
    /// Get restaurant
    /// - Parameters:
    ///     - index : Element number
    /// - Returns: Restaurant
    func getRestaurant(index : Int) -> Restaurant {
        
        return self.data[index]
    }
    
    
    /// Get city from filtered data
    /// - Returns: Number of elements
    func getNumberOfElements() -> Int {
        
        return self.data.count
    }
    
    /// Fetch data to object
    func fetchData() {
        
        let apiCaller = API_Caller(URL: "https://api.yelp.com/v3/businesses/search?location=NYC&term=restaurants", httpMethodType: .GET, authenticationType: .None)
        
        apiCaller.callAPI(dataParameter: nil, customHeaders: ["Authorization" : "Bearer sw1r12sSNGhci4KixgOSIJkAUrD-pBHFrRdiulLEAhM-HAJi67Tw0hmRKM_zkl51rfQCk7UQAcfFDMcSN0BkqcH073EI45PrqbqmtAhQkSKEVcvVPKj5yW7eGizLXHYx"]) {
            
            (code, data, response) in
            
            guard code == "200", let data_ = data as? Data else {
                
                return
            }
            
            // Get data and parse it
            do {
                
                // Get Data and parse it
                let businesses = try JSONDecoder().decode(Businesses.self, from: data_)
                
                DispatchQueue.main.async {
                    
                    //Update data objects
                    self.data = businesses.businesses
                }
                
            } catch {
                
                // handle error
                print("Error: \(error)")
            }
            
        }
        
    }
    
    
}
