//
//  Constants.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation
import UIKit


// MARK: - All the text strings and other things that should only be in one place

struct Constants {
    
    // The testing vars are in Utility.swift
    
    static let appVersionNumber: Double = 0.1
    static let AppVersion = String(format: "%1.2f", appVersionNumber)
    static let AppDate = "30 October 2017"
    
    static let MaxPopoverWidth = 320.0
    static let ImageViewLayerCornerRadius: CGFloat = 5.0
    
    static let AppNameText = "TouristHelper"
    
    // MARK: - General Constants
    
    static let DefaultLatitudeDeltaForFirstSpan: Double = 0.01
    static let DefaultLongitudeDeltaForFirstSpan: Double = 0.01
    static let MinLatitudeDeltaSpan: Double = 0.001
    static let MinLongitudeDeltaSpan: Double = 0.001
    static let MaxLatitudeDeltaSpan: Double = 0.1
    static let MaxLongitudeDeltaSpan: Double = 0.1
    
    // MARK: - Globally used Storyboard constants
    
    
    
    // MARK: - All Text Strings
    
    static let GenericKillAppReasonText = "This App is not currently available. Sorry for any inconvenince."
    static let AppHasExpiredText = "This version is no longer supported. Please upgrade."
    static let OKText = "OK"
    static let DoneText = "Done"
    static let DoneEditingText = "Done Editing"
    static let CancelText = "Cancel"
    static let NextText = "Next"
    static let ConfirmText = "Confirm"
    static let YesText = "Yes"
    static let TryAgainText = "Try again"
    static let ErrorText = "Error"
    static let AreYouSureText = "Are You Sure?"
    static let AppVersionText = "App Version"
    static let ContactUsText = "Contact Us"
    static let AboutText = "About \(AppNameText)"
    static let PrivacyText = "Privacy"
    static let WarningText = "Warning"
    static let SettingsText = "Settings"
    static let EditText = "Edit"
    static let SaveText = "Save"
    static let PullToRefreshText = "" // "Pull to refresh"
    
    static let SortAlphabeticallyText = "Sort Alphabetically"
    static let SortByLocationText = "Sort by distance from here"
    static let MapText = "Map"
    static let ListText = "List"
    static let HotSpotText = "Hot Spot"
    static let LocationText = "Location"
    static let CantGetCurrentLocationForRouteText = "Can't get your current location to make a route"
    static let RouteNeedsToBeInRegionText = "Please move the map so it contains your current location.\n\nThen we can draw your route for you"
    static let OptionsText = "Options"
    static let DisplayHotSpotsText = "Display places as Hot Spots"
    static let DisplayPinsText = "Display places as Pins"
    static let DisplayRouteText = "Show a best route from here"
    static let DisplayNothingText = "Clear the map of places"
    static let DataSourceText = "Data Source"
    static let SelectionNotAvailableText = "Selection not available"
}
