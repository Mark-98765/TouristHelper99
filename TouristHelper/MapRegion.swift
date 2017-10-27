//
//  MapRegion.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation
import MapKit

struct MapRegion {
    
    var latitude_ll: Double?
    var longitude_ll: Double?
    var latitude_ur: Double?
    var longitude_ur: Double?
    
    func isNotNil() -> Bool {
        if latitude_ll != nil &&
            longitude_ll != nil &&
            latitude_ur != nil &&
            longitude_ur != nil {
            return true
        }
        return false
    }
    
    func requestParameters() -> [String: Double]? {
        if !self.isNotNil() {
            return nil
        }
        
        var requestParameters = [String: Double]()
        requestParameters[ServerParameters.latitude_ll] = latitude_ll!
        requestParameters[ServerParameters.longitude_ll] = longitude_ll!
        requestParameters[ServerParameters.latitude_ur] = latitude_ur!
        requestParameters[ServerParameters.longitude_ur] = longitude_ur!
        
        return requestParameters
    }
    
    func contains(_ location: CLLocationCoordinate2D) -> Bool {
        guard let lat_ll = latitude_ll, let lat_ur = latitude_ur,
              let long_ll = longitude_ll, let long_ur = longitude_ur else {
            return false
        }
        
        let lat = location.latitude
        let long = location.longitude
        
        // Note: Doesn't do 180 degree problems
        if lat >= lat_ll && lat <= lat_ur &&
            long >= long_ll && long <= long_ur {
            return true
        }
        return false
    }
    
}

// MARK: - Extension - Equatable

extension MapRegion: Equatable {}

func ==(lhs: MapRegion, rhs: MapRegion) -> Bool {
    if lhs.latitude_ll == rhs.latitude_ll &&
        lhs.longitude_ll == rhs.longitude_ll &&
        lhs.latitude_ur == rhs.latitude_ur &&
        lhs.longitude_ur == rhs.longitude_ur {
        return true
    }
    return false
}
