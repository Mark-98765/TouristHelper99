//
//  PlaceOfInterest.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation
import UIKit
import MapKit


struct PlaceOfInterest {
    
    var latitude: Double
    var longitude: Double
    var distanceFromHere: Double
    var text: String
    
    // Note: Only Foursquare is catered for, ATM
    
    static func placesOfInterestFrom(serverResponseData: Any?) -> [PlaceOfInterest]? {
        printLog("placesOfInterestFrom()")
        
        guard let jsonData = serverResponseData as? [String: Any],
              let responseData = jsonData["response"] as? [String: Any],
              let venueArray = responseData["venues"] as? [[String: Any]] else {
            printLog("placesOfInterestFrom() nil/invalid json dictionary/array")
            return nil
        }
        
        // printLog("placesOfInterestFrom() venueData=\(venueArray[0])")
        
        var placesOfInterest = [PlaceOfInterest]()
        
        for venueData in venueArray {
            guard let name = venueData["name"] as? String,
                  let locationData = venueData["location"] as? [String: Any] else {
                continue
            }
            
            if let lat = locationData["lat"] as? Double, let lng = locationData["lng"] as? Double,
               let lastLocation = UserPrefs.lastLocation() {
                
                let coordinate = CLLocation(latitude: lat, longitude: lng)
                let lastLocationCoordinate = CLLocation(latitude: lastLocation.0, longitude: lastLocation.1)
                let distanceFromHere = coordinate.distance(from: lastLocationCoordinate)
                
                printLog("Venue: \(name) \(lat) \(lng) distance=\(distanceFromHere)")
                
                let placeOfInterest = PlaceOfInterest(latitude: lat, longitude: lng, distanceFromHere: distanceFromHere, text: name)
                placesOfInterest.append(placeOfInterest)
            }
        }
        
        return placesOfInterest
    }
    
    static func waypointCoordinatesForDirections(_ placesOfInterest: [PlaceOfInterest]?) -> [CLLocationCoordinate2D]? {
        guard let points = placesOfInterest, points.count > 0 else {
            return nil
        }
        
        let places = points.sorted {
            $0.distanceFromHere < $1.distanceFromHere
        }
        
        var waypoints = [CLLocationCoordinate2D]()
        for place in places {
            waypoints.append(CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))
        }
        return waypoints
    }
    
    
}

// MARK: - Extension - Equatable

extension PlaceOfInterest: Equatable {}

func ==(lhs: PlaceOfInterest, rhs: PlaceOfInterest) -> Bool {
    return (lhs.latitude == rhs.latitude) && (lhs.longitude == rhs.longitude) && (lhs.text == rhs.text)
}
