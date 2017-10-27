//
//  TabBarViewController.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import UIKit

enum PlacesOfInterestRequestSource {
    case map
    case list
}

enum PlacesOfInterestSortType {
    case alphabetic
    case distance
}


class TabBarViewController: UITabBarController {
    
    // If the Map requests the places of interest but we switch to the List in the meantime, we need to do a reload()
    var requestSource: PlacesOfInterestRequestSource = .map
    var currentSelectedViewController: UIViewController?
    
    var placesOfInterestSortType: PlacesOfInterestSortType = .distance
    
    var placesOfInterest: [PlaceOfInterest]? {
        didSet {
            if requestSource == .map {
                if let vc = selectedViewController as? ListViewController {
                    DispatchQueue.main.async {
                        // Main queue because we may be calling this during the completion block of a server request
                        vc.reloadData()
                    }
                }
            }
            
            guard !(selectedViewController is ListViewController) else { return }
            // And badge the List View Tab Item, if we're not doing a refresh from within the List View
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                guard let viewControllers = strongSelf.viewControllers else { return }
                
                for viewController in viewControllers {
                    if let vc = viewController as? ListViewController {
                        if let locationData = strongSelf.placesOfInterest, locationData.count > 0 {
                            vc.tabBarItem.badgeValue = "\(locationData.count)"
                        } else {
                            vc.tabBarItem.badgeValue = nil
                        }
                    }
                }
            }
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        
        if let vcs = self.viewControllers {
            for vc in vcs {
                if vc is MapViewController {
                    currentSelectedViewController = vc
                    selectedViewController = vc
                    vc.tabBarItem.title = Constants.MapText
                    vc.tabBarItem.image = UIImage(named: "401-globe")
                } else if vc is ListViewController {
                    vc.tabBarItem.title = Constants.ListText
                    vc.tabBarItem.image = UIImage(named: "329-layers1")
                } else if vc is SettingsViewController {
                    vc.tabBarItem.title = Constants.SettingsText
                    vc.tabBarItem.image = UIImage(named: "668-gear4")
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate: Bool {
        get {
            // return false
            if let vc = self.selectedViewController {
                return vc.shouldAutorotate
            }
            return super.shouldAutorotate
        }
    }
    
    // MARK: - Processing methods
    
    func addAnnotationForPlaceOfInterest(_ placeOfInterest: PlaceOfInterest) {
        if viewControllers == nil {
            return
        }
        
        for viewController in viewControllers! {
            if let vc = viewController as? MapViewController {
                vc.addAnnotationForPlaceOfInterest(placeOfInterest)
                self.selectedViewController = vc
            }
        }
    }
    
    func addAnnotationForPlaceOfInterestAndMoveToLocation(for placeOfInterest: PlaceOfInterest) {
        if viewControllers == nil {
            return
        }
        
        for viewController in viewControllers! {
            if let vc = viewController as? MapViewController {
                vc.addAnnotationForPlaceOfInterestAndMoveToLocation(for: placeOfInterest)
                self.selectedViewController = vc
            }
        }
    }
    
    func processLocationDataOnServerReturn(_ locationData: [PlaceOfInterest]?) {
        printLog("processLocationDataOnServerReturn()")
        
        guard var processedLocationData = locationData else {
            placesOfInterest = nil
            return
        }
        
        // Sort them
        switch placesOfInterestSortType {
        case .distance:
            processedLocationData.sort {
                return $0.distanceFromHere < $1.distanceFromHere
            }
        case .alphabetic:
            processedLocationData.sort {
                return $0.text < $1.text
            }
        }
        
        placesOfInterest = processedLocationData
    }
    
    // MARK: - Alert methods
    
    func showAppInvalidAlert() {
        if let reason = appIsInvalidReason() {
            showOKAlert(title: Constants.AppNameText, message: reason, presentingViewController: self, handler: nil)
        }
    }
    

}


extension TabBarViewController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.currentSelectedViewController = viewController
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if !appIsValid() {
            showAppInvalidAlert()
            return false
        }
        
        return true
    }
}
