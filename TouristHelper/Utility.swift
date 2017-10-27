//
//  Utility.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation
import UIKit
import MapKit


//----------------------------------
// To Do List for release
//
// In Utility.swift:
// Change appIsTesting = false
//
// In Constants.swift:
// Change: minAppVersion, AppVersion, AppDate
//
// Double check in TransactionService.swift for the BaseAddress functions
//
// Check the VersionHistory.rtf is up to date
//
//----------------------------------

// MARK: -  Global variables
// (Note: This is the ONLY file where there are globals: variables and functions)

// Start of change stuff for release

var appIsTesting: Bool = true // Set false for release

// End of change stuff for release

var appUsesServerCalls: Bool {
    get {
        /*
         if appIsTesting {
         return true // false // true
         }
         */
        if isRegistered() {
            return true
        }
        // Not registered/logged in
        return false // true // Change for testing
    }
}

var appUsesLocalData: Bool {
    get {
        return !appUsesServerCalls
    }
}


var minAppVersionFromServer: String? = nil
var killApp: Bool = false // Can be set to true by a getSystemInfo() server request to get the system_info
var killAppReason: String? = nil // Set by the getSystemInfo() server request return, it's what's displayed in an alert

// MARK: -  Global functions

func printLog(_ string: String) {
    if appIsTesting {
        print("\(string)")
    } else {
        // Do nothing. All prints will be removed
    }
}

func isRegistered() -> Bool {
    if UserPrefs.email() != nil {
        return true
    }
    return false
}

func appIsValid() -> Bool {
    // Check if the app hasn't been killed and the ios version is OK
    if killApp {
        return false
    }
    
    if let miniOSVersion = minAppVersionFromServer, let minVersion = Double(miniOSVersion) {
        if Constants.appVersionNumber < minVersion {
            return false
        }
    }
    
    return true
}

func appIsInvalidReason() -> String? {
    if appIsValid() {
        return nil
    }
    
    if killApp {
        if let reason = killAppReason {
            return reason
        }
        return Constants.GenericKillAppReasonText
    }
    
    if let miniOSVersion = minAppVersionFromServer, let minVersion = Double(miniOSVersion) {
        if Constants.appVersionNumber < minVersion {
            return Constants.AppHasExpiredText
        }
    }
    
    return nil // Shouldn't ever get here
}

func navigationBarAppearance() {
    UINavigationBar.appearance().barTintColor = systemColor()
    UINavigationBar.appearance().tintColor = navigationBarTitleTintColor()
    UINavigationBar.appearance().titleTextAttributes = navigationBarTitleTextAttributes()
}

func navigationBarTitleTextAttributes() -> [String : Any]? {
    // return [NSForegroundColorAttributeName:UIColor.white, NSFontAttributeName:UIFont.italicSystemFont(ofSize: 17.0)]
    return [NSForegroundColorAttributeName:UIColor.white, NSFontAttributeName:UIFont.preferredFont(forTextStyle: .title1)]
}

func navigationBarTitleTintColor() -> UIColor {
    return UIColor.white
}

func systemColor() -> UIColor {
    return UIColor(red: 39/255, green: 173/255, blue: 209/255, alpha: 1)
}

func systemLightGrayColor() -> UIColor {
    return UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
}

func systemDarkGrayColor() -> UIColor {
    return UIColor.darkGray
}

func tableViewBackgroundColor() -> UIColor {
    return systemLightGrayColor()
}

func tableViewCellBackgroundColor() -> UIColor {
    return systemLightGrayColor()
}

func chooseBarTintColor() -> UIColor {
    return UIColor.lightGray
}

func linkTextColor() -> UIColor {
    
    // From https://en.wikipedia.org/wiki/Help:Link_color
    
    return UIColor(red: 6/255, green: 69/255, blue: 173/255, alpha: 1.0)
}

func showOKAlert(title: String, message: String, presentingViewController: UIViewController, handler: ((UIAlertAction) -> Void)?) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let actionOK = UIAlertAction(title: Constants.OKText, style: .default, handler: handler)
    alertController.addAction(actionOK)
    presentingViewController.present(alertController, animated: true, completion: nil)
}

func mapCoordinateRegionFrom(mapRegion: MapRegion) -> MKCoordinateRegion {
    var newMapRegion = mapRegion
    if !mapRegion.isNotNil() {
        // Hmmm!! Just use Melbourne
        newMapRegion = MapRegion(latitude_ll: -38.2, longitude_ll: 144.7, latitude_ur: -37.4, longitude_ur: 145.1)
    }
    return mapCoordinateRegionFrom(latitudeLl: newMapRegion.latitude_ll!, longitudeLl: newMapRegion.longitude_ll!, latitudeUr: newMapRegion.latitude_ur!, longitudeUr: newMapRegion.longitude_ur!)
}

func mapCoordinateRegionFrom(latitudeLl: Double, longitudeLl: Double, latitudeUr: Double, longitudeUr: Double) -> MKCoordinateRegion {
    let latitudeDifference = latitudeUr - latitudeLl
    let centerLatitude = latitudeLl + (latitudeDifference/2.0)
    var longitudeDifference = longitudeUr - longitudeLl
    var centerLongitude = longitudeLl + (longitudeDifference/2.0)
    
    if longitudeUr < 0.0 && longitudeLl > 0.0 {
        // The region spans the 180 degree meridian
        longitudeDifference = (longitudeUr + 180.0) + (180.0 - longitudeLl)
        centerLongitude = longitudeLl + (longitudeDifference/2.0)
        if centerLongitude > 180.0 {
            // It's more on the Eastern side, so change the number around
            centerLongitude = centerLongitude - 360.0
        }
    }
    
    let center = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    let span = MKCoordinateSpanMake(latitudeDifference, longitudeDifference)
    
    let region = MKCoordinateRegionMake(center, span)
    return region
}

func mapRegionFrom(coordinateRegion: MKCoordinateRegion) -> MapRegion {
    let centerLatitude = coordinateRegion.center.latitude
    let centerLongitude = coordinateRegion.center.longitude
    let latitudeDelta = coordinateRegion.span.latitudeDelta
    let longitudeDelta = coordinateRegion.span.longitudeDelta
    
    let latitude_ll = centerLatitude - (latitudeDelta/2.0)
    let latitude_ur = centerLatitude + (latitudeDelta/2.0)
    
    var longitude_ll = centerLongitude - (longitudeDelta/2.0)
    var longitude_ur = centerLongitude + (longitudeDelta/2.0)
    
    if longitude_ll < -180.0 {
        longitude_ll = longitude_ll + 360.0
    }
    
    if longitude_ur > 180.0 {
        longitude_ur = longitude_ur - 360.0
    }
    
    let mapRegion = MapRegion(latitude_ll: latitude_ll, longitude_ll: longitude_ll, latitude_ur: latitude_ur, longitude_ur: longitude_ur)
    return mapRegion
}




