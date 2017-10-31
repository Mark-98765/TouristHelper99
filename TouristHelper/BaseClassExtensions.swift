//
//  BaseClassExtensions.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation
import UIKit
import MapKit

// MARK: - Some useful extensions to base classes

extension RangeReplaceableCollection where Iterator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(_ object : Iterator.Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
}

extension String {
    var length: Int {
        return characters.count
    }
    
    func isEmail() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]+$", options: NSRegularExpression.Options.caseInsensitive)
            return regex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.characters.count)) != nil
        } catch { return false }
    }
    
    func withReplacedCharacters(_ characters: String, by separator: String) -> String {
        let characterSet = CharacterSet(charactersIn: characters)
        return components(separatedBy: characterSet).joined(separator: separator)
    }
}

extension Double {
    func roundToPlaces(_ places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        let doubleValue = self
        let result = (doubleValue * divisor).rounded()
        return result / divisor
    }
    
    func format(places f: Int) -> String {
        // return String(format: "%.\(f)f", self)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = f
        let doubleValue = self
        if let retValue = formatter.string(from: NSNumber(value: doubleValue.roundToPlaces(f))) {
            return retValue
        }
        return "\(self)"
    }
}

extension Dictionary where Value : Equatable {
    func allKeysForValue(_ val : Value) -> [Key] {
        return self.filter { $1 == val }.map { $0.0 }
    }
}

extension Array where Element : Equatable {
    mutating func remove(_ element: Element) {
        if let index = self.index(of: element) {
            self.remove(at: index)
        }
    }
    
    mutating func removeObjectsInArray(_ array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}

extension Date {
    func formattedMediumStyle() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: self)
    }
    
}

extension UITextField {
    func setBottomBorder(size: CGSize, color: UIColor) {
        
        // Remove any previous border layer(s)
        let borderLayerName = "TextFieldBorderLayerX" // Fixed value for these (don't change)
        if let sublayers = self.layer.sublayers {
            for sublayer in sublayers {
                if sublayer.name == borderLayerName {
                    sublayer.removeFromSuperlayer()
                }
            }
        }
        // self.borderStyle = UITextBorderStyle.none
        let border = CALayer()
        let width = CGFloat(1.0)
        border.name = borderLayerName
        border.borderColor = color.cgColor
        border.frame = CGRect(x: 0.0, y: size.height - width, width: size.width, height: size.height)
        border.borderWidth = width
        printLog("UITextField setBottomBorder size.width=\(size.width)")
        
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
    }
}

extension CLLocationCoordinate2D: Equatable {}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return (lhs.latitude == rhs.latitude) && (lhs.longitude == rhs.longitude)
}


