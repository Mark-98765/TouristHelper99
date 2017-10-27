//
//  TouristHelperTests.swift
//  TouristHelperTests
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import XCTest
@testable import TouristHelper

class TouristHelperTests: XCTestCase {
    
    var controllerUnderTest: TabBarViewController!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        controllerUnderTest = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! TabBarViewController!
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        controllerUnderTest = nil
        super.tearDown()
    }
    
    func testFoursquareDataFetch() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let promise = expectation(description: "Foursquare data returned")
        
        let mapRegion = UserPrefs.currentMapRegion()
        XCTAssertNotNil(mapRegion, "current map region is nil")
        // XCTAssertNil(mapRegion, "current map region is not nil")
        
        TransactionService.getPlacesOfInterest(for: mapRegion!) { (response, mapRegionUsedForRequest, data) in
            
            if response.status == .success {
                if let _ = PlaceOfInterest.placesOfInterestFrom(serverResponseData: data) {
                    promise.fulfill()
                } else {
                    XCTFail("Successful return but no data")
                }
            } else {
                XCTFail("Failed return")
            }
            
        }
        waitForExpectations(timeout: 6, handler: nil)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
