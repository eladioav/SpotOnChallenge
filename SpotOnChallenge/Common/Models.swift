//
//  Models.swift
//  SpotOnChallenge
//
//  Created by Eladio Alvarez Valle on 5/2/19.
//  Copyright © 2019 Eladio Alvarez Valle. All rights reserved.
//

import Foundation

struct Businesses : Codable {

    var businesses : [Restaurant]
}

struct Restaurant: Codable {
    
    var id : String
    var alias : String
    var name : String
    var image_url : String
    var is_closed : Bool
    var url : String
    var review_count :Int
    var categories : [Categories]
    var rating : Float
    var coordinates : Coordinates
    var transactions : [String]?
    var price : String?
    var location : Location
    var phone : String
    var display_phone : String
    var distance : Double
}

struct Categories : Codable {
    var alias : String
    var title : String
}

struct Coordinates : Codable {
    
    var latitude : Double
    var longitude : Double
}

struct Location : Codable {
    
    var address1 : String?
    var address2 : String?
    var address3 : String?
    var city : String
    var zip_code : String
    var country : String
    var state : String
    var display_address : [String]?
}
