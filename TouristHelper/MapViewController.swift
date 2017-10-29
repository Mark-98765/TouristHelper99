//
//  MapViewController.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var gotoCurrentLocationButton: UIButton!
    
    @IBAction func gotoCurrentLocationButtonAction(_ sender: UIButton) {
        gotoCurrentLocation()
        
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorContainerView: UIView!
    
    @IBOutlet weak var hotSpotButton: UIButton!
    @IBAction func hotSpotButtonAction(_ sender: UIButton) {
        showMenu()
    }
    
    fileprivate struct Storyboard {
        static let AnnotationIdentifier = "AnnotationIdentifier"
        static let ColorsViewHeightRestraintConstant: CGFloat = 20.0
        
        static let ColorLabelFrameHeight: CGFloat = 20.0
        static let ColorLabelFrameWidth: CGFloat = 20.0
        static let ColorDescriptionLabelFrameHeight: CGFloat = 20.0
        static let ColorDescriptionLabelFrameWidth: CGFloat = 35.0
        static let GapBetweenColorLabels: CGFloat = 3.0
        static let LegendViewGap: CGFloat = 10.0
        
        static let PlaceOfInterestAnnotationIdentifier = "PlaceOfInterestAnnotationIdentifier"
        
        static let ShowFirstLoadSegueIdentifier = "ShowFirstLoadSegueIdentifier"
    }
    
    enum AnnotationDisplayMode {
        case pin
        case overlay
        case route
        case none
    }
    
    
    let locationManager = CLLocationManager()
    let useSignificantLocationChanges = true
    
    var tabBarViewController: TabBarViewController? // Used to hold the data array, so we can share it between here and the List
    
    var regionDidChangeAnimatedCompletion: (() -> Void)?
    
    var colorLegendView: UIView?
    var annotationDisplayMode: AnnotationDisplayMode = .overlay // .route // .pin
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tbc = self.tabBarController as? TabBarViewController {
            tabBarViewController = tbc
        }

        tabBarItem.title = Constants.MapText
        tabBarItem.image = UIImage(named: "401-globe")
        
        mapView.delegate = self
        
        let text = Constants.AppNameText
        titleLabel.attributedText = NSAttributedString(string: text, attributes: navigationBarTitleTextAttributes())
        self.titleLabel.textColor = systemColor()
        
        hideActivityIndicator() // Just in case...
        activityIndicator.color = systemColor()
        activityIndicatorContainerView.backgroundColor = .white
        activityIndicatorContainerView.isHidden = true
        activityIndicatorContainerView.layer.cornerRadius = Constants.ImageViewLayerCornerRadius
        activityIndicatorContainerView.clipsToBounds = true
        
        hotSpotButton.setTitle(Constants.OptionsText, for: .normal)
        hotSpotButton.layer.cornerRadius = Constants.ImageViewLayerCornerRadius
        hotSpotButton.clipsToBounds = true
        hotSpotButton.backgroundColor = .lightGray
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        
        // Testing...
        UserPrefs.setShownFirstLoadViews(true)
        
        
        initLocationAndMap()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserPrefs.hasShownFirstLoadViews() {
            // Set up the user prefs defaults
            UserPrefs.setDefaults()
            printLog("MapViewController viewDidAppear About to segue to FirstLoad1VC")
            // performSegue(withIdentifier: Storyboard.ShowFirstLoadSegueIdentifier, sender: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate: Bool {
        get {
            return super.shouldAutorotate // false // Testing...
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if colorLegendView != nil {
            colorLegendView!.isHidden = true
        }
        
        let completion: (UIViewControllerTransitionCoordinatorContext) -> Void = { [weak self] (coordinatorContext) -> Void in
            guard let strongSelf = self else { return }
            printLog("viewWillTransition completion")
            switch strongSelf.annotationDisplayMode {
            case .overlay:
                strongSelf.showHotSpots()
            case .pin:
                strongSelf.showPins()
            case .none:
                strongSelf.showNothing()
            case .route:
                strongSelf.showRoute()
            }
        }
        
        coordinator.animate(alongsideTransition: nil, completion: completion)
    }
    
    // MARK: - Init/Setup methods
    
    func initLocationAndMap() {
        if UserPrefs.hasShownFirstLoadViews() {
            printLog("MapViewController initLocationAndMap() setupLocationMonitoring()")
            setupLocationMonitoring()
        }
        
        if let currentMapRegion = UserPrefs.currentMapRegion() {
            printLog("MapViewController initLocationAndMap() got map region")
            mapView.setRegion(mapCoordinateRegionFrom(mapRegion: currentMapRegion), animated: true)
        } else {
            printLog("MapViewController initLocationAndMap() No map region")
            // No map region saved yet.
            if let lastLocation = UserPrefs.lastLocation() {
                printLog("MapViewController initLocationAndMap() No map region But got a location")
                // Got a location fix, construct a "default" map region and show that
                let span = MKCoordinateSpan(latitudeDelta: Constants.DefaultLatitudeDeltaForFirstSpan, longitudeDelta: Constants.DefaultLongitudeDeltaForFirstSpan)
                let center = CLLocationCoordinate2DMake(lastLocation.0, lastLocation.1)
                let coordinateRegion = MKCoordinateRegion(center: center, span: span)
                mapView.setRegion(coordinateRegion, animated: true)
            } else {
                printLog("MapViewController initLocationAndMap() No map region And no location as well")
                // Got nothing yet. Just let it fall through and let the user play with it.
            }
        }
    }
    
    func initPlaceOfInterestDensityColorLegend(placeOfInterestGridArray: [PlaceOfInterestGrid]) {
        // The colors will depend on the max count...
        
        let descriptionFont = UIFont.systemFont(ofSize: 10.0)
        
        // Remove any old ones
        if self.colorLegendView != nil {
            self.colorLegendView!.isHidden = true
            for subview in colorLegendView!.subviews {
                if subview.isKind(of: PlaceOfInterestDensityColorLabel.self) {
                    subview.removeFromSuperview()
                } else if subview.isKind(of: PlaceOfInterestDensityColorDescriptionLabel.self) {
                    subview.removeFromSuperview()
                }
            }
            self.colorLegendView!.removeFromSuperview()
            self.colorLegendView = nil
        }
        
        // Just grab any one of the grid elements, they'll all know about the color distribution
        if placeOfInterestGridArray.count == 0 {
            // Nothing to do here...
            return
        }
        
        let maxCount = placeOfInterestGridArray[0].maxCountForAllGrids
        let colorsLegend = PlaceOfInterestDensityColor.placeOfInterestDensityColorsLegend(maxCount: maxCount)
        printLog("initPlaceOfInterestDensityColorLegend() placeOfInterestGridArray[0].maxCountForAllGrids=\(placeOfInterestGridArray[0].maxCountForAllGrids)")
        if colorsLegend.count == 0 {
            // Problems...
            return
        }
        
        let legendView = UIView()
        let colorLabelFrame = CGRect(x: 0, y: 0, width: Storyboard.ColorLabelFrameWidth, height: Storyboard.ColorLabelFrameHeight)
        let colorDescriptionLabelFrame = CGRect(x: Storyboard.ColorLabelFrameWidth + Storyboard.GapBetweenColorLabels, y: 0, width: Storyboard.ColorDescriptionLabelFrameWidth, height: Storyboard.ColorDescriptionLabelFrameHeight)
        
        let startIndex = colorsLegend.count - 1
        printLog("initPlaceOfInterestDensityColorLegend() startIndex=\(startIndex)")
        for index in (0...startIndex).reversed() {
            let newColorLabel = PlaceOfInterestDensityColorLabel(color: colorsLegend[index].color.withAlphaComponent(PlaceOfInterestDensityColor.alpha))
            var originY: CGFloat = colorLabelFrame.origin.y + (CGFloat((startIndex - index)) * colorLabelFrame.size.height)
            
            newColorLabel.frame = CGRect(x: colorLabelFrame.origin.x, y: originY, width: colorLabelFrame.size.width, height: colorLabelFrame.size.height)
            
            let newColorDescriptionLabel = PlaceOfInterestDensityColorDescriptionLabel(text: colorsLegend[index].description, font: descriptionFont)
            originY = colorDescriptionLabelFrame.origin.y + (CGFloat((startIndex - index)) * colorDescriptionLabelFrame.size.height)
            newColorDescriptionLabel.frame = CGRect(x: colorDescriptionLabelFrame.origin.x, y: originY, width: colorDescriptionLabelFrame.size.width, height: colorDescriptionLabelFrame.size.height)
            
            legendView.addSubview(newColorLabel)
            legendView.addSubview(newColorDescriptionLabel)
        }
        
        let hotSpotButtonFrame = self.hotSpotButton.frame
        let legendViewHeight = Storyboard.ColorLabelFrameHeight * CGFloat(colorsLegend.count)
        let legendViewWidth = Storyboard.ColorLabelFrameWidth + Storyboard.ColorDescriptionLabelFrameWidth
        let legendViewY = hotSpotButtonFrame.origin.y - legendViewHeight - Storyboard.LegendViewGap // Add a gap too
        let legendViewX = hotSpotButtonFrame.origin.x + ((hotSpotButtonFrame.size.width - legendViewWidth)/2.0)
        let legendViewFrame = CGRect(x: legendViewX, y: legendViewY, width: legendViewWidth, height: legendViewHeight)
        legendView.frame = legendViewFrame
        legendView.backgroundColor = .white
        
        self.colorLegendView = legendView
        self.colorLegendView?.isHidden = true
        self.view.addSubview(self.colorLegendView!)
        
    }
    
    func showColorsLegend() {
        if colorLegendView != nil {
            colorLegendView!.isHidden = false
        }
    }
    
    // MARK: - Notifications
    
    func applicationDidBecomeActive() {
        // We have to re-start the location monitoring
        printLog("MapViewController applicationDidBecomeActive()")
        if UserPrefs.hasShownFirstLoadViews() {
            printLog("MapViewController applicationDidBecomeActive() setupLocationMonitoring()")
            setupLocationMonitoring()
        }
    }
    
    // MARK: - Action methods
    
    func showMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: Constants.DisplayHotSpotsText, style: .default) { (action) in
            self.annotationDisplayMode = .overlay
            self.showHotSpots()
        })
        alert.addAction(UIAlertAction(title: Constants.DisplayPinsText, style: .default) { (action) in
            self.annotationDisplayMode = .pin
            self.showPins()
        })
        alert.addAction(UIAlertAction(title: Constants.DisplayRouteText, style: .default) { (action) in
            self.annotationDisplayMode = .route
            self.showRoute()
        })
        alert.addAction(UIAlertAction(title: Constants.DisplayNothingText, style: .default) { (action) in
            self.annotationDisplayMode = .none
            self.showNothing()
        })
        
        alert.addAction(UIAlertAction(title: Constants.CancelText, style: .cancel) { (action) in
            // Do nothing
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showHotSpots() {
        showNothing()
        
        reloadMapOverlayData()
        showColorsLegend()
    }
    
    func showRoute() {
        showNothing()
        
        guard let mapRegion = UserPrefs.currentMapRegion() else {
            printLog("showRoute() Can't get mapRegion")
            return
        }
        
        guard let lastLocation = UserPrefs.lastLocation() else {
            // Can't get last location, so no route
            let title = Constants.LocationText
            let message = Constants.CantGetCurrentLocationForRouteText
            showOKAlert(title: title, message: message, presentingViewController: self, handler: nil)
            return
        }
        
        let lastLocationCoordinate = CLLocationCoordinate2D(latitude: lastLocation.0, longitude: lastLocation.1)
        
        if !mapRegion.contains(lastLocationCoordinate) {
            // Can't get last location, so no route
            let title = Constants.LocationText
            let message = Constants.RouteNeedsToBeInRegionText
            showOKAlert(title: title, message: message, presentingViewController: self, handler: nil)
            return
        }
        
        guard let tbc = tabBarViewController,
              let placesOfInterest = tbc.placesOfInterest, placesOfInterest.count > 2,
              let coordinates = PlaceOfInterest.waypointCoordinatesForDirections(placesOfInterest) else {
                printLog("showRoute() Can't get coordinates")
            return
        }
        
        addRouteForAllPlacesOfInterest(startCoordinate: CLLocationCoordinate2D(latitude: lastLocation.0, longitude: lastLocation.1), coordinates: coordinates)
    }
    
    func showPins() {
        showNothing()
        
        if let placesOfInterest = tabBarViewController?.placesOfInterest {
            addAnnotationsForAllPlacesOfInterest(placesOfInterest)
        }
    }
    
    func showNothing() {
        removeOverlays()
        if let legendView = colorLegendView {
            legendView.isHidden = true
        }
        
    }
    
    func showActivityIndicator() {
        activityIndicator.startAnimating()
        activityIndicatorContainerView.isHidden = false
    }
    
    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicatorContainerView.isHidden = true
    }
    
    func gotoCurrentLocation() {
        printLog("gotoCurrentLocation()")
        if let lastLocation = UserPrefs.lastLocation() {
            printLog("gotoCurrentLocation() Has Last Location")
            let center = CLLocationCoordinate2DMake(lastLocation.0, lastLocation.1)
            let currentSpan = mapView.region.span
            let coordinateRegion = MKCoordinateRegion(center: center, span: currentSpan)
            mapView.setRegion(coordinateRegion, animated: true)
        }
    }
    
    // MARK: - Remove annotations and overlays methods
    
    func removeAnnotations(type: PlaceOfInterestAnnotationType) {
        
        var annotationsToRemove = [MKAnnotation]()
        for annotation in mapView.annotations {
            if let pinAnnotation = annotation as? PlaceOfInterestAnnotation {
                if pinAnnotation.annotationType == type {
                    annotationsToRemove.append(pinAnnotation)
                }
            }
        }
        mapView.removeAnnotations(annotationsToRemove)
    }
    
    func removeOverlays() {
        var overlaysToRemove = [MKOverlay]()
        for overlay in mapView.overlays {
            if overlay.isKind(of: PlaceOfInterestDensityCircleOverlay.self) {
                overlaysToRemove.append(overlay)
            } else if overlay.isKind(of: RouteOverlay.self) {
                overlaysToRemove.append(overlay)
            }
        }
        mapView.removeOverlays(overlaysToRemove)
        
        // And the annotations
        removeAnnotations(type: .selectedPlaceOfInterest)
        removeAnnotations(type: .allPlacesOfInterest)
    }
    
    // MARK: - Add annotations methods
    
    func addAnnotationForPlaceOfInterest(_ placeOfInterest: PlaceOfInterest) {
        let latitude = placeOfInterest.latitude
        let longitude = placeOfInterest.longitude
        
        showNothing()
        
        printLog("MapViewController addAnnotationForPlaceOfInterest() ")
        let selectedAnnotation = PlaceOfInterestAnnotation(coordinate: CLLocationCoordinate2DMake(latitude, longitude))
        selectedAnnotation.annotationType = .selectedPlaceOfInterest
        mapView.addAnnotation(selectedAnnotation)
    }
    
    func addAnnotationForPlaceOfInterestAndMoveToLocation(for placeOfInterest: PlaceOfInterest) {
        let latitude = placeOfInterest.latitude
        let longitude = placeOfInterest.longitude
        
        showNothing()
        
        printLog("MapViewController addAnnotationForPlaceOfInterestAndMoveToLocation() ")
        let annotationCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
        let selectedAnnotation = PlaceOfInterestAnnotation(coordinate: annotationCoordinate)
        selectedAnnotation.annotationType = .selectedPlaceOfInterest
        
        regionDidChangeAnimatedCompletion = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.mapView.addAnnotation(selectedAnnotation)
        }
        
        var region = mapView.region
        region.center = annotationCoordinate
        mapView.setRegion(region, animated: true)
    }
    
    func addAnnotationsForAllPlacesOfInterest(_ placesOfInterest: [PlaceOfInterest]) {
        removeAnnotations(type: .selectedPlaceOfInterest)
        removeAnnotations(type: .allPlacesOfInterest)
        for placeOfInterest in placesOfInterest {
            let latitude = placeOfInterest.latitude
            let longitude = placeOfInterest.longitude
            let selectedAnnotation = PlaceOfInterestAnnotation(coordinate: CLLocationCoordinate2DMake(latitude, longitude))
            selectedAnnotation.annotationType = .allPlacesOfInterest
            mapView.addAnnotation(selectedAnnotation)
        }
    }
    
    func addRouteForAllPlacesOfInterest(startCoordinate: CLLocationCoordinate2D, coordinates: [CLLocationCoordinate2D]) {
        
        var places = coordinates
        places.insert(startCoordinate, at: 0)
        places.append(startCoordinate)
        
        // Really guys?
        // Give an expected time of 8 hours to do the whole app and also expect a working implementation of Dijkstra's algorithm?
        // Hmmm.
        // This is what happens when you set arbitrary deadlines.
 
        let geodesic = RouteOverlay(coordinates: places, count: places.count)
        mapView.add(geodesic)
        
    }
    
    // MARK: - Location
    
    func setupLocationMonitoring() {
        
        if !CLLocationManager.locationServicesEnabled() {
            printLog("MapViewController setupLocation !CLLocationManager.locationServicesEnabled()")
            return
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        let status = CLLocationManager.authorizationStatus()
        printLog("MapViewController setupLocation status=\(status.rawValue)")
        if status != .denied {
            if status != .authorizedWhenInUse {
                printLog("MapViewController setupLocation status != .authorizedWhenInUse")
                locationManager.requestWhenInUseAuthorization()
            } else {
                printLog("MapViewController setupLocation locationManager.requestLocation()")
                locationManager.requestLocation()
                
                if self.useSignificantLocationChanges {
                    printLog("MapViewController locationManager.startMonitoringSignificantLocationChanges()")
                    if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                        locationManager.startMonitoringSignificantLocationChanges()
                    } else {
                        printLog("MapViewController locationManager.significantLocationChangeMonitoringAvailable() NOT AVAILABLE")
                    }
                } else {
                    // locationManager.requestLocation()
                    locationManager.startUpdatingLocation()
                }
            }
        } else {
            // denied. Do nothing.
        }
    }

    // MARK: - Data processing
    
    func reloadMapOverlayData() {
        printLog("MapViewController: reloadMapOverlayData()")
        showNothing()
        
        guard let placesOfInterest = tabBarViewController?.placesOfInterest else { return }
        printLog("MapViewController: reloadMapOverlayData() placesOfInterest.count=\(placesOfInterest.count)")
        
        guard let mapRegion = UserPrefs.currentMapRegion() else { printLog("MapViewController reloadMapOverlayData() no saved map region"); return }
        
        guard var placesOfInterestGridArray = makePlaceOfInterestDensityGrid(for: mapRegion, using: placesOfInterest) else { printLog("MapViewController makePlacesOfInterestDensityGrid() returned nil"); return }
        
        // We need to know the weight of counts against the max count for all the grids
        // so we can calulate the relative fillColor schemes
        
        let maxCountForAllGrids = placesOfInterestGridArray.reduce(0) { (maxCount, placeOfInterestGrid) -> Int in
            if placeOfInterestGrid.count > maxCount {
                return placeOfInterestGrid.count
            }
            return maxCount
        }
        
        printLog("MapViewController reloadMapOverlayData() maxCountForAllGrids\(maxCountForAllGrids)")
        
        // Add the overlays
        // And add annotations for all the pins within the overlays (testing)
        var allPlacesOfInterestInAllGrids = [PlaceOfInterest]()
        // And we need to update the array (to get the maxCountForAllGrids in there)
        var updatedPlaceOfInterestGridArray = [PlaceOfInterestGrid]()
        
        for placeOfInterestGrid in placesOfInterestGridArray {
            var placeOfInterestGridToAdd = placeOfInterestGrid
            placeOfInterestGridToAdd.maxCountForAllGrids = maxCountForAllGrids
            
            // MKCircle
            let placeOfInterestDensityOverlay = PlaceOfInterestDensityCircleOverlay(center: placeOfInterestGridToAdd.center, radius: placeOfInterestGridToAdd.radius)
            placeOfInterestDensityOverlay.placeOfInterestGrid = placeOfInterestGridToAdd
            mapView.add(placeOfInterestDensityOverlay)
            
            updatedPlaceOfInterestGridArray.append(placeOfInterestGridToAdd)
            
            // Note. We create the grid by removing places of interest after each pass through, so there shouldn't be duplicates.
            let allPlacesOfInterestInThisGrid = [placeOfInterestGrid.centerPlaceOfInterest] + placeOfInterestGrid.otherPlacesOfInterest
            allPlacesOfInterestInAllGrids += allPlacesOfInterestInThisGrid
        }
        
        // Replace with the updated one
        placesOfInterestGridArray = updatedPlaceOfInterestGridArray
        
        // Now we know how the grid looks we can setup the color legend
        initPlaceOfInterestDensityColorLegend(placeOfInterestGridArray: placesOfInterestGridArray)
        showColorsLegend()
        
        printLog("All Places of Interest In All Grids count=\(allPlacesOfInterestInAllGrids.count)")
        
    }
    
    func makePlaceOfInterestDensityGrid(for mapRegion: MapRegion, using placesOfInterest: [PlaceOfInterest]) -> [PlaceOfInterestGrid]? {
        return makePlaceOfInterestDensityGridRemovingAlreadyConsideredPlacesOfInterest(for: mapRegion, using: placesOfInterest)
    }
    
    func makePlaceOfInterestDensityGridRemovingAlreadyConsideredPlacesOfInterest(for mapRegion: MapRegion, using placesOfInterest: [PlaceOfInterest]) -> [PlaceOfInterestGrid]? {
        
        // This method repeatedly goes through the the array, finding the one with the most counts (around it)
        // then removing ALL those and going through all the remaining. Etc.
        // Until we reach maxLoopCycles or run out of places of interest (<2)
        guard let latitude_ll = mapRegion.latitude_ll, let latitude_ur = mapRegion.latitude_ur,
            let longitude_ll = mapRegion.longitude_ll, let longitude_ur = mapRegion.longitude_ur else { return nil }
        
        let maxPlacesOfInterestToCount: Int = 1 // 2
        let maxLoopCycles: Int = 4 // 15 // The max number of overlays on the map
        let deltaFraction = 0.15 // 0.20 // Percent
        let maxDelta = 0.01 // The maximum delta allowed for the smallest delta
        
        if placesOfInterest.count < maxPlacesOfInterestToCount {
            return nil
        }
        
        // Calculate the deltas for the region
        let latitudeDelta = latitude_ur - latitude_ll
        var longitudeDelta = longitude_ur - longitude_ll
        if longitude_ll > longitude_ur {
            // Straddles 180
            longitudeDelta = (180.0 - longitude_ll) + (longitude_ur + 180.0)
        }
        
        var finalPlaceOfInterestGrid = [PlaceOfInterestGrid]()
        
        var gridLatitudeDelta = latitudeDelta * deltaFraction
        var gridLongitudeDelta = longitudeDelta * deltaFraction
        
        printLog("Original gridLatitudeDelta=\(gridLatitudeDelta) gridLongitudeDelta=\(gridLongitudeDelta)")
        
        let smallestDelta = min(gridLatitudeDelta, gridLongitudeDelta)
        if  smallestDelta > maxDelta {
            // The smallest delta is too big
            let ratio = maxDelta / smallestDelta
            gridLatitudeDelta = gridLatitudeDelta * ratio
            gridLongitudeDelta = gridLongitudeDelta * ratio
            printLog("After gridLatitudeDelta=\(gridLatitudeDelta) gridLongitudeDelta=\(gridLongitudeDelta)")
        }
        
        var remainingPlacesOfInterest = placesOfInterest // Start with all of them
        var placesOfInterestToCheck = remainingPlacesOfInterest
        
        printLog("START remainingPlacesOfInterest.count=\(remainingPlacesOfInterest.count)")
        
        for index in 1...maxLoopCycles { // But we may not get to the end
            printLog("index=\(index)")
            var tempPlaceOfInterestGrid = [PlaceOfInterestGrid]()
            
            // Cycle through one by one, capturing all the places of interest within the deltas of the center one
            
            printLog("index=\(index) placesOfInterestToCheck.count=\(placesOfInterestToCheck.count)")
            for placeOfInterest in placesOfInterestToCheck {
                // guard let latitude = placeOfInterest.latitude, let longitude = placeOfInterest.longitude else { continue }
                let latitude = placeOfInterest.latitude
                let longitude = placeOfInterest.longitude
                
                let placeOfInterestGridLatitude_ll = latitude - (gridLatitudeDelta/2.0)
                let placeOfInterestGridLatitude_ur = latitude + (gridLatitudeDelta/2.0)
                let placeOfInterestGridLongitude_ll = longitude - (gridLongitudeDelta/2.0)
                let placeOfInterestGridLongitude_ur = longitude + (gridLongitudeDelta/2.0)
                
                // Get all within the bounds of the deltas above (but not including the center one)
                let otherPlacesOfInterest = remainingPlacesOfInterest.filter({ (remainingPlaceOfInterest) -> Bool in
                    // guard let remainingLatitude = remainingPlaceOfInterest.latitude, let remainingLongitude = remainingPlaceOfInterest.longitude else { return false }
                    let remainingLatitude = remainingPlaceOfInterest.latitude
                    let remainingLongitude = remainingPlaceOfInterest.longitude
                    
                    if remainingLatitude > placeOfInterestGridLatitude_ll &&
                        remainingLatitude <= placeOfInterestGridLatitude_ur &&
                        remainingLongitude > placeOfInterestGridLongitude_ll &&
                        remainingLongitude <= placeOfInterestGridLongitude_ur {
                        return true
                    }
                    return false
                })
                
                let placeOfInterestGrid = PlaceOfInterestGrid(centerPlaceOfInterest: placeOfInterest, otherPlacesOfInterest: otherPlacesOfInterest, centerLatitude: latitude, centerLongitude: longitude, latitudeDelta: gridLatitudeDelta, longitudeDelta: gridLongitudeDelta)
                tempPlaceOfInterestGrid.append(placeOfInterestGrid)
            }
            
            printLog("index=\(index) tempPlaceOfInterestGrid.count=\(tempPlaceOfInterestGrid.count)")
            
            // So, tempPlaceOfInterestGrid contains a record for EVERY place of interest (remainingPlacesOfInterest).
            
            // Find which one of these has the greatest "count"
            guard let maxCountPlaceOfInterestGrid = PlaceOfInterestGrid.getGridWithMaxCount(tempPlaceOfInterestGrid) else {
                printLog("index=\(index) maxCountPlaceOfInterestGrid == nil. Break Loop")
                break
            }
            
            printLog("index=\(index) maxCountPlaceOfInterestGrid.count=\(maxCountPlaceOfInterestGrid.count)")
            
            // If the max count is 1, we're done! (And don't add this one to the array)
            if maxCountPlaceOfInterestGrid.count == 1 {
                printLog("index=\(index) maxCountPlaceOfInterestGrid.count == 1. Break Loop")
                break
            }
            
            // Add this one to the final grid array
            finalPlaceOfInterestGrid.append(maxCountPlaceOfInterestGrid)
            
            // Remove all the places of interest in the finalPlaceOfInterestGrid array of PlaceOfInterestGrids from the places of interest remaining for consideration
            let tempRemainingPlacesOfInterest = PlaceOfInterestGrid.removeAllPlacesOfInterest(from: remainingPlacesOfInterest, using: finalPlaceOfInterestGrid)
            remainingPlacesOfInterest = tempRemainingPlacesOfInterest
            printLog("index=\(index) remainingPlacesOfInterest.count=\(remainingPlacesOfInterest.count)")
            
            // If there's only 1 left, we're done!
            if remainingPlacesOfInterest.count < maxPlacesOfInterestToCount {
                printLog("index=\(index) remainingPlacesOfInterest.count < maxPlacesOfInterestToCount. Break Loop")
                break
            }
            
            // Reset the array
            placesOfInterestToCheck = remainingPlacesOfInterest
            
            // Go around again
            // index += 1
        }
        
        printLog("END index=\(index) finalPlaceOfInterestGrid.count=\(finalPlaceOfInterestGrid.count)")
        return finalPlaceOfInterestGrid
    }
    
    
    // MARK: - Navigation

}


// MARK: - Extension - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        printLog("MapViewController regionDidChangeAnimated -----------------")
        
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedWhenInUse && !UserPrefs.hasObtainedFirstLocationFix() {
            printLog("MapViewController regionDidChangeAnimated No location fix")
            return
        }
        
        var coordinateRegionThatFits = mapView.region // We may need to change this
        
        printLog("MapViewController regionDidChangeAnimated mapViewRegion Span=\(coordinateRegionThatFits.span)")
        
        if coordinateRegionThatFits.span.latitudeDelta > Constants.MaxLatitudeDeltaSpan {
            // Too big. Zoom in.
            printLog("MapViewController regionDidChangeAnimated mapRegion is too big")
            let span = MKCoordinateSpan(latitudeDelta: Constants.MaxLatitudeDeltaSpan, longitudeDelta: Constants.MaxLongitudeDeltaSpan)
            let coordinateMapRegionFirstAttempt = MKCoordinateRegion(center: coordinateRegionThatFits.center, span: span)
            coordinateRegionThatFits = self.mapView.regionThatFits(coordinateMapRegionFirstAttempt)
            printLog("MapViewController regionDidChangeAnimated coordinateRegionThatFits Span=\(coordinateRegionThatFits.span)")
            printLog("MapViewController regionDidChangeAnimated About to set region to coordinateRegionThatFits")
            self.mapView.setRegion(coordinateRegionThatFits, animated: true)
        } else if coordinateRegionThatFits.span.latitudeDelta < Constants.MinLatitudeDeltaSpan {
            // Too small. Zoom out.
            printLog("MapViewController regionDidChangeAnimated mapRegion is too small")
            let span = MKCoordinateSpan(latitudeDelta: Constants.MinLatitudeDeltaSpan, longitudeDelta: Constants.MinLongitudeDeltaSpan)
            let coordinateMapRegionFirstAttempt = MKCoordinateRegion(center: coordinateRegionThatFits.center, span: span)
            coordinateRegionThatFits = self.mapView.regionThatFits(coordinateMapRegionFirstAttempt)
            printLog("MapViewController regionDidChangeAnimated coordinateRegionThatFits Span=\(coordinateRegionThatFits.span)")
            printLog("MapViewController regionDidChangeAnimated About to set region to coordinateRegionThatFits")
            mapView.setRegion(coordinateRegionThatFits, animated: true)
        }
        
        // So, all the region changes are taken care of. Save the map co-ordinates and re-get the data
        let mapRegion = mapRegionFrom(coordinateRegion: coordinateRegionThatFits)
        printLog("MapViewController regionDidChangeAnimated Set UserPrefs to mapRegion=\(mapRegion)")
        UserPrefs.setCurrentMapRegion(mapRegion)
        
        getPlacesOfInterest()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        if let pinAnnotation = annotation as? PlaceOfInterestAnnotation {
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: Storyboard.PlaceOfInterestAnnotationIdentifier)
                as? MKPinAnnotationView {
                dequeuedView.annotation = pinAnnotation
                dequeuedView.pinTintColor = pinAnnotation.pinTintColor
                view = dequeuedView
            } else {
                // Create one
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Storyboard.PlaceOfInterestAnnotationIdentifier)
                view.canShowCallout = true // false
                view.animatesDrop = true
                view.pinTintColor = pinAnnotation.pinTintColor
            }
            return view
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlayView = overlay as? PlaceOfInterestDensityCircleOverlay {
            printLog("MapViewController rendererFor MKCircle")
            //  MKCircle
            guard let placeOfInterestGrid = overlayView.placeOfInterestGrid else { return MKOverlayRenderer(overlay: overlay) }
            
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.fillColor = placeOfInterestGrid.fillColor
            circleRenderer.strokeColor = placeOfInterestGrid.strokeColor
            circleRenderer.lineWidth = placeOfInterestGrid.lineWidth
            return circleRenderer
        } else if let overlayView = overlay as? RouteOverlay {
            printLog("MapViewController rendererFor MKPolyline")
            //  MKPolyline
            let renderer = MKPolylineRenderer(polyline: overlayView)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 2
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}

// MARK: - Extension - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            printLog("MapViewController Current location: timestamp=\(location.timestamp) latitude=\(location.coordinate.latitude) longitude=\(location.coordinate.longitude)")
            UserPrefs.setLastLocation((location.coordinate.latitude,location.coordinate.longitude))
            
            // First time through. Go to current location.
            if !UserPrefs.hasObtainedFirstLocationFix() {
                UserPrefs.setHasObtainedFirstLocationFix(true)
                printLog("MapViewController didUpdateLocations no location processing begin1")
                if let lastLocation = UserPrefs.lastLocation() {
                    printLog("MapViewController didUpdateLocations no location processng begin2")
                    let center = CLLocationCoordinate2DMake(lastLocation.0, lastLocation.1)
                    let currentSpan = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5) // self.mapView.region.span
                    let coordinateRegion = MKCoordinateRegion(center: center, span: currentSpan)
                    mapView.setRegion(coordinateRegion, animated: false)
                    
                    let mapRegion = mapRegionFrom(coordinateRegion: mapView.region)
                    UserPrefs.setCurrentMapRegion(mapRegion)
                    
                    printLog("MapViewController didUpdateLocations First time. About to getPlacesOfInterest()")
                    getPlacesOfInterest()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        printLog("MapViewController locationManager didFailWithError error=\(error)")
    }
    
}

// MARK: - Extension - Data retrieval/Server methods

extension MapViewController {
    
    func getPlacesOfInterest() {
        if !appIsValid() {
            printLog("MapViewController getPlacesOfInterest() App is Invalid")
            return
        }
        
        printLog("MapViewController getPlacesOfInterest()")
        
        guard let mapRegion = UserPrefs.currentMapRegion() else { return }
        printLog("MapViewController getPlacesOfInterest() mapRegion=\(mapRegion)")
        
        tabBarViewController?.requestSource = .map // So if we switch to the list before the server return we do a reload()
        showActivityIndicator()
        
        TransactionService.getPlacesOfInterest(for: mapRegion) { [weak self] (response, mapRegionUsedForRequest, data) in
            guard let strongSelf = self else { return }
            printLog("getPlacesOfInterest() call completed")
            DispatchQueue.main.async {
                strongSelf.hideActivityIndicator()
            }
            
            if mapRegionUsedForRequest != UserPrefs.currentMapRegion() {
                // They've moved the map in the meantime. Don't worry about this request.
                printLog("MapViewController  getPlacesOfInterest() map region has changed. Aborting.")
                return
            }
            
            strongSelf.tabBarViewController?.placesOfInterest = nil
            if response.status == .success {
                if let responseData = PlaceOfInterest.placesOfInterestFrom(serverResponseData: data) {
                    let locationData = responseData
                    strongSelf.tabBarViewController?.processLocationDataOnServerReturn(locationData)
                } else {
                    // Successful return but no data. That's OK here.
                    printLog("MapViewController  getPlacesOfInterest() return but no data. ")
                }
                DispatchQueue.main.async {
                    // Reload the map data...
                    printLog("MapViewController TransactionService.getPlacesOfInterest() About to reloadMapOverlayData()")
                    switch strongSelf.annotationDisplayMode {
                    case .overlay:
                        strongSelf.showHotSpots()
                    case .pin:
                        strongSelf.showPins()
                    case .none:
                        strongSelf.showNothing()
                    case .route:
                        strongSelf.showRoute()
                    }
                    
                    if let completion = strongSelf.regionDidChangeAnimatedCompletion {
                        completion()
                        strongSelf.regionDidChangeAnimatedCompletion = nil
                    }
                }
            } else {
                // Error
                DispatchQueue.main.async {
                    TransactionService.processServerError(response, presentingViewController: strongSelf)
                }
            }
        }
        
    }
    
    func getDirections() {
        printLog("MapViewController getDirections()")
        
        guard let lastLocation = UserPrefs.lastLocation(),
              let mapRegion = UserPrefs.currentMapRegion(),
              let placesCoordinates = PlaceOfInterest.waypointCoordinatesForDirections(tabBarViewController?.placesOfInterest) else {
            return
        }
        
        let origin = CLLocationCoordinate2D(latitude: lastLocation.0, longitude: lastLocation.1)
        
        showActivityIndicator()
        TransactionService.getDirections(origin: origin, destination: origin, waypointCoordinates: placesCoordinates) { [weak self] (response, data) in
            guard let strongSelf = self else { return }
            printLog("getDirections() call completed")
            DispatchQueue.main.async {
                strongSelf.hideActivityIndicator()
            }
            
            if mapRegion != UserPrefs.currentMapRegion() {
                // They've moved the map in the meantime. Don't worry about this request.
                printLog("MapViewController  getDirections() map region has changed. Aborting.")
                return
            }
            
            if response.status == .success {
                printLog("getDirections() data=\(String(describing: data))")
                
                
                
            } else {
                // Error
                DispatchQueue.main.async {
                    TransactionService.processServerError(response, presentingViewController: strongSelf)
                }
            }
        }
        
        
        
    }
    
}




