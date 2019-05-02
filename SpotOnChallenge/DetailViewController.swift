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
    var coordinates : Coordinates?
    
    func configureView() {
        // Update the user interface for the detail item.
        
        
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
    }
    
    /// Center map on location
    func centerMapOnLocation(location: CLLocation) {
        
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        self.map.setRegion(coordinateRegion, animated: true)
    }


}

