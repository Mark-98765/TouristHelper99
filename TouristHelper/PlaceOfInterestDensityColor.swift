//
//  PlaceOfInterestDensityColor.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation
import UIKit

struct PlaceOfInterestDensityColor {
    
    // Increasing number means increasing density
    // These are similar to the bom heat map
    
    var color: UIColor
    var lowerRange: Int // Inclusive
    var upperRange: Int? // Inclusive (last one will be nil)
    
    var description: String {
        get {
            if upperRange == nil {
                return "\(lowerRange)+"
            } else {
                return "\(lowerRange)+"
            }
        }
    }
    
    static let color11 = UIColor(red: 255/255, green: 253/255, blue: 198/255, alpha: 1.0)
    static let color12 = UIColor(red: 253/255, green: 254/255, blue: 39/255, alpha: 1.0)
    static let color13 = UIColor(red: 255/255, green: 201/255, blue: 111/255, alpha: 1.0)
    static let color14 = UIColor(red: 254/255, green: 205/255, blue: 191/255, alpha: 1.0)
    static let color15 = UIColor(red: 252/255, green: 154/255, blue: 151/255, alpha: 1.0)
    static let color16 = UIColor(red: 241/255, green: 60/255, blue: 53/255, alpha: 1.0)
    static let color17 = UIColor(red: 255/255, green: 100/255, blue: 10/255, alpha: 1.0)
    static let color18 = UIColor(red: 255/255, green: 20/255, blue: 0/255, alpha: 1.0)
    static let color19 = UIColor(red: 20/255, green: 10/255, blue: 0/255, alpha: 1.0)
    
    // Old values, I don't like them.
    // static let color18 = UIColor(red: 152/255, green: 102/255, blue: 53/255, alpha: 1.0)
    // static let color19 = UIColor(red: 165/255, green: 50/255, blue: 0/255, alpha: 1.0)
    
    static let numberOfColors: Int = 9
    static let alpha: CGFloat = 0.6
    
    static func placeOfInterestDensityAllColorsArray() -> [UIColor] {
        // Return an array in order, from less intensity to highest intensity
        var colorsArray = [UIColor]()
        colorsArray.append(PlaceOfInterestDensityColor.color11)
        colorsArray.append(PlaceOfInterestDensityColor.color12)
        colorsArray.append(PlaceOfInterestDensityColor.color13)
        colorsArray.append(PlaceOfInterestDensityColor.color14)
        colorsArray.append(PlaceOfInterestDensityColor.color15)
        colorsArray.append(PlaceOfInterestDensityColor.color16)
        colorsArray.append(PlaceOfInterestDensityColor.color17)
        colorsArray.append(PlaceOfInterestDensityColor.color18)
        colorsArray.append(PlaceOfInterestDensityColor.color19)
        
        return colorsArray
    }
    
    static func getPlaceOfInterestDensityColor(for placeOfInterestCount: Int, maxCount: Int) -> UIColor {
        
        let colorsArray = PlaceOfInterestDensityColor.placeOfInterestDensityColorsLegend(maxCount: maxCount)
        
        for placeOfInterestDensityColor in colorsArray {
            if placeOfInterestCount >= placeOfInterestDensityColor.lowerRange {
                if placeOfInterestDensityColor.upperRange == nil {
                    return placeOfInterestDensityColor.color
                }
                // upperRange is not nil, need to check inclusive range
                if placeOfInterestCount <= placeOfInterestDensityColor.upperRange! {
                    return placeOfInterestDensityColor.color
                }
            }
            // Go around again...
        }
        
        // Problems...
        return .blue
    }
    
    static func placeOfInterestDensityColorsLegend(maxCount: Int) -> [PlaceOfInterestDensityColor] {
        // Return the legend of colors, depends on max count
        var colorsArray = [PlaceOfInterestDensityColor]()
        
        if maxCount <= 10 {
            colorsArray.append(PlaceOfInterestDensityColor(color: PlaceOfInterestDensityColor.color17, lowerRange: 1, upperRange: 3))
            colorsArray.append(PlaceOfInterestDensityColor(color: PlaceOfInterestDensityColor.color18, lowerRange: 4, upperRange: 7))
            colorsArray.append(PlaceOfInterestDensityColor(color: PlaceOfInterestDensityColor.color19, lowerRange: 8, upperRange: nil))
            return colorsArray
        } else if maxCount <= 20 {
            colorsArray.append(PlaceOfInterestDensityColor(color: PlaceOfInterestDensityColor.color14, lowerRange: 1, upperRange: 3))
            colorsArray.append(PlaceOfInterestDensityColor(color: PlaceOfInterestDensityColor.color15, lowerRange: 4, upperRange: 7))
            colorsArray.append(PlaceOfInterestDensityColor(color: PlaceOfInterestDensityColor.color16, lowerRange: 8, upperRange: 10))
            colorsArray.append(PlaceOfInterestDensityColor(color: PlaceOfInterestDensityColor.color17, lowerRange: 11, upperRange: 14))
            colorsArray.append(PlaceOfInterestDensityColor(color: PlaceOfInterestDensityColor.color18, lowerRange: 15, upperRange: 17))
            colorsArray.append(PlaceOfInterestDensityColor(color: PlaceOfInterestDensityColor.color19, lowerRange: 18, upperRange: nil))
            return colorsArray
        } else {
            let range = Int(Double(maxCount/PlaceOfInterestDensityColor.numberOfColors).rounded())
            printLog("PlaceOfInterestDensityColor.placeOfInterestDensityColorsLegend() range=\(range) maxCount=\(maxCount)")
            let allColors = PlaceOfInterestDensityColor.placeOfInterestDensityAllColorsArray()
            var lowerRange: Int = 1
            for index in 0...numberOfColors - 1 {
                printLog("PlaceOfInterestDensityColor.placeOfInterestDensityColorsLegend() index=\(index)")
                let upperRange: Int = lowerRange + range
                if index == numberOfColors - 1 {
                    colorsArray.append(PlaceOfInterestDensityColor(color: allColors[index], lowerRange: lowerRange, upperRange: nil))
                } else {
                    colorsArray.append(PlaceOfInterestDensityColor(color: allColors[index], lowerRange: lowerRange, upperRange: upperRange))
                }
                lowerRange = upperRange + 1
            }
            
            return colorsArray
        }
    }
    
    init(color: UIColor, lowerRange: Int, upperRange: Int?) {
        self.color = color
        self.lowerRange = lowerRange
        self.upperRange = upperRange
    }
    
}
