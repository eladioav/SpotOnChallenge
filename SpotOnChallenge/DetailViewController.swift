//
//  DetailViewController.swift
//  SpotOnChallenge
//
//  Created by Eladio Alvarez Valle on 5/2/19.
//  Copyright © 2019 Eladio Alvarez Valle. All rights reserved.
//

import UIKit
import MapKit

class DetailViewController: UIViewController {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    var restaurant : Restaurant?
    let regionRadius: CLLocationDistance = 100
    
    func configureView() {
        // Update the user interface for the detail item.
        if let coord = restaurant?.coordinates {
            let coordinates = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            self.centerMapOnLocation(location: coordinates, title: restaurant?.name ?? "No name")
        }
        
        self.addressLabel.text = restaurant?.location.address1 ?? "No address"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        map.mapType = .satelliteFlyover
        configureView()
    }
    
    /// Center map on location
    func centerMapOnLocation(location: CLLocation, title : String) {
        
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        var annotation = MapPin(coordinate: coordinateRegion.center, title: title, subtitle: "Here")
        self.map.addAnnotation(annotation)
        self.map.setRegion(coordinateRegion, animated: true)
    }


}

