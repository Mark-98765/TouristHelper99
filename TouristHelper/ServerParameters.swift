//
//  ServerParameters.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation

struct ServerParameters {
    // Must be exactly the same string values as on the server(s)
    static let latitude = "latitude"
    static let longitude = "longitude"
    static let latitude_ll = "latitude_ll"
    static let longitude_ll = "longitude_ll"
    static let latitude_ur = "latitude_ur"
    static let longitude_ur = "longitude_ur"
    static let min_version_ios = "min_version_ios"
    static let min_version_android = "min_version_android"
    static let kill_app = "kill_app"
    static let kill_app_reason = "kill_app_reason"
    static let error_code = "error_code"
    static let error_message = "error_message"
    
    // Foursquare
    static let sw = "sw"
    static let ne = "ne"
    static let intent = "intent"
    static let limit = "limit"
    static let client_id = "client_id"
    static let client_secret = "client_secret"
}
