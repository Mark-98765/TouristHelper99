//
//  PlaceOfInterestDensityColorLabel.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import UIKit

class PlaceOfInterestDensityColorLabel: UILabel {
    
    
    convenience init(color: UIColor) {
        self.init()
        
        self.text = nil
        self.backgroundColor = color
        
    }
    
}
