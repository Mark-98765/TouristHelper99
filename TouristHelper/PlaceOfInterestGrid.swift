//
//  PlaceOfInterestGrid.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation
import MapKit

struct PlaceOfInterestGrid {
    
    // The places of interest around a center palce of interest, within the region bounded by the deltas
    
    var centerPlaceOfInterest: PlaceOfInterest
    var otherPlacesOfInterest: [PlaceOfInterest]
    
    var count: Int {
        get {
            let placeOfInterestCount = otherPlacesOfInterest.count + 1
            return placeOfInterestCount
        }
    }
    
    var maxCountForAllGrids: Int = 1 // Set after we've processed all grids
    
    // centerLatitude/centerLongitude just replicate the values in centerPlaceOfInterest.
    // However, at init, we want to make sure they are NOT optionals (because of center)
    // instead just unwrapping them here, but someone may stuff up at some later stage
    // and centerPlaceOfInterest latitude/longitude may be nil... (Trust no-one)
    var centerLatitude: Double
    var centerLongitude: Double
    
    var latitudeDelta: Double
    var longitudeDelta: Double
    
    var center: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2DMake(centerLatitude, centerLongitude)
        }
    }
    var radius: CLLocationDistance {
        get {
            let longitudeSize = gridLongitudeSize()
            let latitudeSize = gridLatitudeSize()
            let maxRadius = min(longitudeSize, latitudeSize)
            return maxRadius
        }
    }
    
    var fillColor: UIColor {
        get {
            let calculatedColor = PlaceOfInterestDensityColor.getPlaceOfInterestDensityColor(for: count, maxCount: maxCountForAllGrids)
            return calculatedColor.withAlphaComponent(PlaceOfInterestDensityColor.alpha)
        }
    }
    var strokeColor: UIColor {
        get {
            let calculatedColor = PlaceOfInterestDensityColor.getPlaceOfInterestDensityColor(for: count, maxCount: maxCountForAllGrids)
            return calculatedColor.withAlphaComponent(PlaceOfInterestDensityColor.alpha)
        }
    }
    var lineWidth: CGFloat {
        get {
            return 1.0
        }
    }
    
    init(centerPlaceOfInterest: PlaceOfInterest, otherPlacesOfInterest: [PlaceOfInterest], centerLatitude: Double, centerLongitude: Double, latitudeDelta: Double, longitudeDelta: Double) {
        self.centerPlaceOfInterest = centerPlaceOfInterest
        self.otherPlacesOfInterest = otherPlacesOfInterest
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
    
    // MARK: - Class Methods
    
    static func getGridWithMaxCount(_ placeOfInterestGrids: [PlaceOfInterestGrid]) -> PlaceOfInterestGrid? {
        
        let placeOfInterestGridToReturn: PlaceOfInterestGrid? = nil
        
        let maxCountPlaceOfInterestGrid = placeOfInterestGrids.reduce(placeOfInterestGridToReturn) { (placeOfInterestGridToReturn, placeOfInterestGrid) -> PlaceOfInterestGrid? in
            if placeOfInterestGridToReturn == nil {
                if placeOfInterestGrid.count > 0 {
                    return placeOfInterestGrid
                }
            } else {
                if placeOfInterestGridToReturn!.count < placeOfInterestGrid.count {
                    return placeOfInterestGrid
                }
            }
            return placeOfInterestGridToReturn // Nothing changed
        }
        
        return maxCountPlaceOfInterestGrid
    }
    
    static func removeAllPlacesOfInterest(from placesOfInterest: [PlaceOfInterest], using placeOfInterestGridArray: [PlaceOfInterestGrid]) -> [PlaceOfInterest] {
        
        var retArray = [PlaceOfInterest]()
        
        if placesOfInterest.count == 0 || placeOfInterestGridArray.count == 0 {
            return retArray
        }
        
        var placesOfInterestToRemove = [PlaceOfInterest]()
        
        // Get all the places of interest in the array
        for placeOfInterestGrid in placeOfInterestGridArray {
            placesOfInterestToRemove.append(placeOfInterestGrid.centerPlaceOfInterest)
            placesOfInterestToRemove += placeOfInterestGrid.otherPlacesOfInterest
        }
        
        // Only return a place of interest (from the array) if it's NOT in the placesOfInterestToRemove array
        for placeOfInterest in placesOfInterest {
            if !placesOfInterestToRemove.contains(placeOfInterest) {
                retArray.append(placeOfInterest)
            }
        }
        
        return retArray
    }
    
    // MARK: - Methods
    
    func gridLongitudeSize() -> CLLocationDistance {
        
        let longitudeLeft = centerLongitude - (longitudeDelta/2.0)
        let longitudeRight = centerLongitude + (longitudeDelta/2.0)
        
        let locationLeft = CLLocation(latitude: centerLatitude, longitude: longitudeLeft)
        let locationRight = CLLocation(latitude: centerLatitude, longitude: longitudeRight)
        
        return locationLeft.distance(from: locationRight)
    }
    
    func gridLatitudeSize() -> CLLocationDistance {
        
        let latitudeLower = centerLatitude - (latitudeDelta/2.0)
        let latitudeUpper = centerLatitude + (latitudeDelta/2.0)
        
        let locationLower = CLLocation(latitude: latitudeLower, longitude: centerLongitude)
        let locationUpper = CLLocation(latitude: latitudeUpper, longitude: centerLongitude)
        
        return locationLower.distance(from: locationUpper)
    }
    
    func polygonCoordinates() -> [CLLocationCoordinate2D] {
        
        let latitudeLower = centerLatitude - (latitudeDelta/2.0)
        let latitudeUpper = centerLatitude + (latitudeDelta/2.0)
        var longitudeLeft = centerLongitude - (longitudeDelta/2.0)
        var longitudeRight = centerLongitude + (longitudeDelta/2.0)
        
        // Fix spanning 180
        if longitudeLeft < -180.0 {
            longitudeLeft += 360.0
        }
        if longitudeRight > 180.0 {
            longitudeRight -= 360.0
        }
        
        var coordinates = [CLLocationCoordinate2D]()
        coordinates.append(CLLocationCoordinate2DMake(latitudeLower, longitudeLeft))
        coordinates.append(CLLocationCoordinate2DMake(latitudeLower, longitudeRight))
        coordinates.append(CLLocationCoordinate2DMake(latitudeUpper, longitudeRight))
        coordinates.append(CLLocationCoordinate2DMake(latitudeUpper, longitudeLeft))
        
        return coordinates
    }
    
}
