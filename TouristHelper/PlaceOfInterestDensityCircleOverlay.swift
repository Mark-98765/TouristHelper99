//
//  PlaceOfInterestDensityCircleOverlay.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation
import MapKit

class PlaceOfInterestDensityCircleOverlay: MKCircle {
    
    var placeOfInterestGrid: PlaceOfInterestGrid?
    
    convenience init(placeOfInterestGrid: PlaceOfInterestGrid) {
        self.init()
        self.placeOfInterestGrid = placeOfInterestGrid
    }
    
}
