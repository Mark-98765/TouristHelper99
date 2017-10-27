//
//  PlaceOfInterestAnnotation.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation
import MapKit

enum PlaceOfInterestAnnotationType {
    case selectedPlaceOfInterest
    case allPlacesOfInterest
}


class PlaceOfInterestAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    var pinTintColor: UIColor {
        get {
            switch annotationType {
            case .selectedPlaceOfInterest:
                return MKPinAnnotationView.redPinColor()
            case .allPlacesOfInterest:
                return .black
            }
        }
    }
    
    // The below allows us to remove annotations by type and to have different pin colors.
    var annotationType: PlaceOfInterestAnnotationType = .allPlacesOfInterest // Just a default
    
    init(coordinate: CLLocationCoordinate2D) {
        self.title = nil
        self.subtitle = nil
        self.coordinate = coordinate
        
        super.init()
    }
    
}
