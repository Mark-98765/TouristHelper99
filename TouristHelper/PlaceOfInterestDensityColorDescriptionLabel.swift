//
//  PlaceOfInterestDensityColorDescriptionLabel.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import UIKit

class PlaceOfInterestDensityColorDescriptionLabel: UILabel {
    
    convenience init(text: String, font: UIFont) {
        self.init()
        self.backgroundColor = .clear
        self.textColor = .darkGray
        self.text = text
        self.font = font
    }
    
}

