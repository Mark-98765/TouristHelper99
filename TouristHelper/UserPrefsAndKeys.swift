//
//  UserPrefsAndKeys.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation

struct UserPrefsKeys {
    static let Email = "Email"
    // static let Password = "Password" // MUST go in the keychain!
    static let Phone = "Phone"
    static let Name = "Name"
    static let CompletedInitialSetup = "CompletedInitialSetup"
    static let ShownFirstLoadViews = "ShownFirstLoadViews"
    static let LastLocation = "LastLocation"
    static let CurrentMapRegion = "CurrentMapRegion"
    static let HasObtainedFirstLocationFix = "HasObtainedFirstLocationFix"
    static let ServerDataSource = "ServerDataSource"
}


struct UserPrefs {
    
    static func setDefaults() {
        // Will call this once only, on first time through
    }
    
    static func setEmail(_ value: String?) {
        UserDefaults.standard.set(value, forKey: UserPrefsKeys.Email)
        UserDefaults.standard.synchronize()
    }
    
    static func email() -> String? {
        if let userPrefsValue = UserDefaults.standard.object(forKey: UserPrefsKeys.Email) as? String {
            return userPrefsValue
        }
        return nil
    }
    
    static func setPhone(_ value: String) {
        UserDefaults.standard.set(value, forKey: UserPrefsKeys.Phone)
        UserDefaults.standard.synchronize()
    }
    
    static func phone() -> String? {
        if let userPrefsValue = UserDefaults.standard.object(forKey: UserPrefsKeys.Phone) as? String {
            return userPrefsValue
        }
        return nil
    }
    
    static func setName(_ value: String) {
        UserDefaults.standard.set(value, forKey: UserPrefsKeys.Name)
        UserDefaults.standard.synchronize()
    }
    
    static func name() -> String? {
        if let userPrefsValue = UserDefaults.standard.object(forKey: UserPrefsKeys.Name) as? String {
            return userPrefsValue
        }
        return nil
    }
    
    static func setServerDataSource(_ value: ServerDataSource) {
        UserDefaults.standard.set(value.rawValue, forKey: UserPrefsKeys.ServerDataSource)
        UserDefaults.standard.synchronize()
    }
    
    static func serverDataSource() -> ServerDataSource {
        if let userPrefsValue = UserDefaults.standard.object(forKey: UserPrefsKeys.ServerDataSource) as? String,
           let serverDataSource = ServerDataSource(rawValue: userPrefsValue) {
            return serverDataSource
        }
        return ServerDataSource.foursquare
    }
    
    static func hasCompletedInitialSetup() -> Bool {
        let userPrefsValue = UserDefaults.standard.bool(forKey: UserPrefsKeys.CompletedInitialSetup)
        return userPrefsValue
    }
    
    static func setCompletedInitialSetup(_ userPrefsValue: Bool) {
        UserDefaults.standard.set(userPrefsValue, forKey: UserPrefsKeys.CompletedInitialSetup)
        UserDefaults.standard.synchronize()
    }
    
    static func hasShownFirstLoadViews() -> Bool {
        let userPrefsValue = UserDefaults.standard.bool(forKey: UserPrefsKeys.ShownFirstLoadViews)
        return userPrefsValue
    }
    
    static func setShownFirstLoadViews(_ userPrefsValue: Bool) {
        UserDefaults.standard.set(userPrefsValue, forKey: UserPrefsKeys.ShownFirstLoadViews)
        UserDefaults.standard.synchronize()
    }
    
    static func hasObtainedFirstLocationFix() -> Bool {
        let userPrefsValue = UserDefaults.standard.bool(forKey: UserPrefsKeys.HasObtainedFirstLocationFix)
        return userPrefsValue
    }
    
    static func setHasObtainedFirstLocationFix(_ userPrefsValue: Bool) {
        UserDefaults.standard.set(userPrefsValue, forKey: UserPrefsKeys.HasObtainedFirstLocationFix)
        UserDefaults.standard.synchronize()
    }
    
    static func setLastLocation(_ lastLocation: (Double,Double)) {
        // (Double,Double) == (latitude,longitude)
        var array = [Double]() // Can't save tuples to User defaults
        array.append(lastLocation.0)
        array.append(lastLocation.1)
        UserDefaults.standard.set(array, forKey: UserPrefsKeys.LastLocation)
        UserDefaults.standard.synchronize()
    }
    
    static func lastLocation() -> (Double,Double)? {
        // (Double,Double) == (latitude,longitude)
        if let userPrefsValue = UserDefaults.standard.object(forKey: UserPrefsKeys.LastLocation) as? [Double] {
            if userPrefsValue.count == 2 {
                return (userPrefsValue[0], userPrefsValue[1])
            }
        }
        return nil
    }
    
    static func setCurrentMapRegion(_ mapRegion: MapRegion) {
        var array = [Double]()
        if mapRegion.isNotNil() {
            array.append(mapRegion.latitude_ll!)
            array.append(mapRegion.longitude_ll!)
            array.append(mapRegion.latitude_ur!)
            array.append(mapRegion.longitude_ur!)
            UserDefaults.standard.set(array, forKey: UserPrefsKeys.CurrentMapRegion)
            UserDefaults.standard.synchronize()
        }
    }
    
    static func currentMapRegion() -> MapRegion? {
        if let userPrefsValue = UserDefaults.standard.object(forKey: UserPrefsKeys.CurrentMapRegion) as? [Double] {
            if userPrefsValue.count == 4 {
                return MapRegion(latitude_ll: userPrefsValue[0], longitude_ll: userPrefsValue[1], latitude_ur: userPrefsValue[2], longitude_ur: userPrefsValue[3])
            }
        }
        return nil
    }



}
