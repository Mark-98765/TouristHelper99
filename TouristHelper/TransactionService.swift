//
//  TransactionService.swift
//  TouristHelper
//
//  Created by Mark Macpherson on 26/10/17.
//  Copyright © 2017 Useful Technology. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import MapKit


extension Constants {
    static let ServerCrashedErrorText = "Sorry, there's been a problem.\nThe server was unable to process your request."
    static let ServerRequestFailedErrorText = "Sorry, the server was unable to process your request."
    static let ServerRequestErrorText = "Server Request Error"
    static let UnableToCompleteRequestErrorText = "Sorry. This request could not be completed."
}

enum ServerDataSource: String {
    case foursquare = "foursquare"
    case yelp = "yelp"
    case googlePlaces = "googlePlaces"
    
    func baseUrlString() -> String {
        switch self {
        case .foursquare:
            return TransactionService.foursquareApiBaseAddress + "/" + TransactionService.foursquareApiVersion
        default:
            return TransactionService.foursquareApiBaseAddress + "/" + TransactionService.foursquareApiVersion
        }
    }
}

//------------------------
//
// All Server Request methods are in this file, except:
// See AppDelegate for server requests the require persistence.
//
//------------------------

class TransactionService {
    
    // MARK: - Constant stuff
    
    static let ErrorDomainServerError = "ErrorDomainServerError"
    static let ErrorCodeNilResponseDescription = "Server responded with success but no data"
    static let ErrorCodeParameterErrorDescription = "Parameter Error"
    static let ErrorCodeAuthenticationErrorDescription = "Authentication Error"
    
    static let foursquareClientId = "144EOTKJS5ZMABNBEIOWRTLMGPSE1B3VF2TIJ1BJTUUD01FU"
    static let foursquareClientSecret = "VDBUUTJMMDF1EJKYC5E4EQ3YFHA4KX2RVO30GIUA2TSI55Y0"
    static let foursquareApiBaseAddress = "https://api.foursquare.com"
    static let foursquareApiVersion = "v2"
    
    static let googleDirectionsApiKey = "AIzaSyBGJTC-yg3LVf3YLnhXZbZSDj3PycU1pbg"
    
    static func ApiBaseAddress() -> String {
        // Return the api base depending on various stuff...
        // e.g. Foursquare, Yelp, etc
        
        return ""
        
    }
    
    static func processServerError(_ response: ServiceResponse, presentingViewController: UIViewController) {
        printLog("processServerError() Request=\(response.serverRequest.rawValue)")
        var responseStatusCode: Int = 0
        var urlErrorCode: Int = 0
        var httpStatusCode: Int = 0
        var errorLocalizedDescription = ""
        // var errorJSON: [String: String]?
        var message = Constants.UnableToCompleteRequestErrorText
        let title = response.serverRequest.errorTitle()
        
        if let error = response.serviceResponseError?.alamofireError {
            if let error = error as? AFError {
                switch error {
                case .invalidURL(let url):
                    printLog("Invalid URL: \(url) - \(error.localizedDescription)")
                case .parameterEncodingFailed(let reason):
                    printLog("Parameter encoding failed: \(error.localizedDescription)")
                    printLog("Failure Reason: \(reason)")
                case .multipartEncodingFailed(let reason):
                    printLog("Multipart encoding failed: \(error.localizedDescription)")
                    printLog("Failure Reason: \(reason)")
                case .responseValidationFailed(let reason):
                    printLog("Response validation failed: \(error.localizedDescription)")
                    printLog("Failure Reason: \(reason)")
                    
                    switch reason {
                    case .dataFileNil, .dataFileReadFailed:
                        printLog("Downloaded file could not be read")
                    case .missingContentType(let acceptableContentTypes):
                        printLog("Content Type Missing: \(acceptableContentTypes)")
                    case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                        printLog("Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)")
                    case .unacceptableStatusCode(let code):
                        printLog("Response status code was unacceptable: \(code)")
                        // code == 500 means the server call crashed
                        responseStatusCode = code
                    }
                case .responseSerializationFailed(let reason):
                    printLog("Response serialization failed: \(error.localizedDescription)")
                    printLog("Failure Reason: \(reason)")
                }
                
                printLog("Underlying error: \(String(describing: error.underlyingError))")
                
            } else if let error = error as? URLError {
                printLog("URLError occurred: \(error)")
                urlErrorCode = error.code.rawValue
                errorLocalizedDescription = error.localizedDescription
            } else {
                printLog("Unknown error: \(error)")
            }
        }
        
        if let code = response.serviceResponseError?.statusCode {
            httpStatusCode = code
            printLog("httpStatusCode=\(httpStatusCode)")
        }
        
        if let errorData = response.serviceResponseError?.errorData {
            do {
                if let errorDictionary = try JSONSerialization.jsonObject(with: errorData, options: []) as? [String: String],
                    let errorCode = errorDictionary[ServerParameters.error_code],
                    let errorMessage = errorDictionary[ServerParameters.error_message] {
                    
                    // Include the server request name and error code for testing. Change this after beta testing.
                    message = response.serverRequest.rawValue + " (\(errorCode)) - " + errorMessage
                }
            } catch let error {
                printLog("Server Error handling: JSONSerialization error=\(error)")
                message = message + "\nJSONSerialization error=\(error)"
            }
        }
        
        if responseStatusCode == 500 {
            // Server response crashed
            showOKAlert(title: title, message: Constants.ServerCrashedErrorText, presentingViewController: presentingViewController, handler: nil)
            return // And that's all here
        } else if responseStatusCode == 400 {
            // Server response failed with a "real" error
            showOKAlert(title: title, message: message, presentingViewController: presentingViewController, handler: nil)
            return // And that's all here
        }
        
        if urlErrorCode != 0 {
            // Usually no internet connection (== -1009)
            let message = "\(errorLocalizedDescription) (\(urlErrorCode)). \(Constants.TryAgainText)"
            showOKAlert(title: title, message: message, presentingViewController: presentingViewController, handler: nil)
            return // And that's all here
        }
        
        // Generic server request error display (if we got this far)
        showOKAlert(title: title, message: message, presentingViewController: presentingViewController, handler: nil)
    }
    
    
    static func authorisationParameters() -> [String: Any]? {
        if UserPrefs.serverDataSource() == .foursquare {
            var params = [String: Any]()
            params[ServerParameters.client_id] = TransactionService.foursquareClientId
            params[ServerParameters.client_secret] = TransactionService.foursquareClientSecret
            return params
        }
        
        // Others not done yet
        return nil
    }
    
    // MARK: - Generic Alamofire Request Method
    
    static func makeServerRequest(for requestCall: ServerRequestCall, params: [String: Any]?, completion: @escaping (_ response: ServiceResponse, _ data: Any?) -> Void) {
        let request = Alamofire.request(requestCall.url(), method: .post, parameters: params, encoding: JSONEncoding.default)
        let start = CACurrentMediaTime()
        request.validate()
        request.responseJSON() { response in
            let end = CACurrentMediaTime()
            printLog("\(requestCall.rawValue) duration=\(end - start)")
            
            switch response.result {
            case .success:
                let serviceResponse = ServiceResponse(status: .success, serviceResponseError: nil, serverRequest: requestCall)
                completion(serviceResponse, response.result.value)
            case .failure(let error):
                printLog("\(requestCall.rawValue) server return error:\(error)")
                let returnError = ServiceResponseError(alamofireError: response.error, statusCode: response.response?.statusCode, errorData: response.data)
                let serviceResponse = ServiceResponse(status: .fail, serviceResponseError: returnError, serverRequest: requestCall)
                completion(serviceResponse, nil)
            }
        }
    }
    
    
    // MARK: - Requests
    
    static func getPlacesOfInterest(for mapRegion: MapRegion, completion: @escaping (_ response: ServiceResponse, _ mapRegionUsedForRequest: MapRegion, _ data: Any?) -> Void) {
        let requestCall: ServerRequestCall = .getPlacesOfInterest
            
        var urlString = requestCall.urlString()
                
        if UserPrefs.serverDataSource() == .foursquare {
            guard let latitude_ll = mapRegion.latitude_ll, let longitude_ll = mapRegion.longitude_ll,
                  let latitude_ur = mapRegion.latitude_ur, let longitude_ur = mapRegion.longitude_ur else {
                    // Can't have nil location
                    return
            }
            urlString += "?\(ServerParameters.client_id)=\(TransactionService.foursquareClientId)&\(ServerParameters.client_secret)=\(TransactionService.foursquareClientSecret)&v=20170801"
            urlString += "&\(ServerParameters.sw)=\(latitude_ll),\(longitude_ll)&\(ServerParameters.ne)=\(latitude_ur),\(longitude_ur)"
            urlString += "&\(ServerParameters.intent)=browse&\(ServerParameters.limit)=100"
        }
        
        guard let requestUrl = URL(string: urlString) else {
            return
        }
        
        // makeServerRequest(for: requestCall, params: params, completion: completion)
        
        let request = Alamofire.request(requestUrl, method: .get, parameters: nil, encoding: JSONEncoding.default)
        let start = CACurrentMediaTime()
        request.validate()
        request.responseJSON() { response in
            let end = CACurrentMediaTime()
            printLog("\(requestCall.rawValue) duration=\(end - start)")
            
            switch response.result {
            case .success:
                let serviceResponse = ServiceResponse(status: .success, serviceResponseError: nil, serverRequest: requestCall)
                completion(serviceResponse, mapRegion, response.result.value) // Return the map region we used for this request (to test if it's changed in the meantime)
            case .failure(let error):
                printLog("\(requestCall.rawValue) server return error:\(error)")
                let returnError = ServiceResponseError(alamofireError: response.error, statusCode: response.response?.statusCode, errorData: response.data)
                let serviceResponse = ServiceResponse(status: .fail, serviceResponseError: returnError, serverRequest: requestCall)
                completion(serviceResponse, mapRegion, nil)
            }
        }
    }
    
    static func getDirections(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, waypointCoordinates: [CLLocationCoordinate2D],
                              completion: @escaping (_ response: ServiceResponse, _ data: Any?) -> Void) {
        let requestCall: ServerRequestCall = .getDirections
        
        /*
        if waypointCoordinates.count == 0 {
            return
        }
        */
        
        var urlString = "https://maps.googleapis.com/maps/api/directions/json?"
        urlString += "origin=\(origin.latitude),\(origin.longitude)&destination=\(destination.latitude),\(destination.longitude)"
        urlString += "&mode=walking"
        
        urlString += "&waypoints="
        
        var idx: Int = 0
        for waypoint in waypointCoordinates {
            if idx == 0 {
                urlString += "\(waypoint.latitude),\(waypoint.longitude)"
            } else {
                urlString += "|\(waypoint.latitude),\(waypoint.longitude)"
            }
            idx += 1
        }
        
        urlString += "&key=\(googleDirectionsApiKey)"
        printLog("urlString=\(urlString)")
        
        guard let urlEncoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let requestUrl = URL(string: urlEncoded) else {
                printLog("nil requestURL")
                return
        }
        
        printLog("requestUrl=\(requestUrl)")
        
        let request = Alamofire.request(requestUrl, method: .get, parameters: nil, encoding: JSONEncoding.default)
        let start = CACurrentMediaTime()
        request.validate()
        request.responseJSON() { response in
            let end = CACurrentMediaTime()
            printLog("\(requestCall.rawValue) duration=\(end - start)")
            
            switch response.result {
            case .success:
                let serviceResponse = ServiceResponse(status: .success, serviceResponseError: nil, serverRequest: requestCall)
                completion(serviceResponse, response.result.value) // Return the map region we used for this request (to test if it's changed in the meantime)
            case .failure(let error):
                printLog("\(requestCall.rawValue) server return error:\(error)")
                let returnError = ServiceResponseError(alamofireError: response.error, statusCode: response.response?.statusCode, errorData: response.data)
                let serviceResponse = ServiceResponse(status: .fail, serviceResponseError: returnError, serverRequest: requestCall)
                completion(serviceResponse, nil)
            }
        }
    }
}


enum ResponseStatus {
    case success
    case fail
}

struct ServiceResponse {
    var status: ResponseStatus
    var serviceResponseError: ServiceResponseError?
    var serverRequest: ServerRequestCall
}

struct ServiceResponseError: Error {
    var alamofireError: Error?
    var statusCode: Int?
    var errorData: Data?
}

enum ServerRequestCall: String {
    case getPlacesOfInterest = "getPlacesOfInterest"
    case getDirections = "getDirections"
    case getSystemInfo = "getSystemInfo"
    
    func urlString() -> String {
        let serverDataSourceBaseUrlString = UserPrefs.serverDataSource().baseUrlString()
        switch self {
        case .getPlacesOfInterest:
            return serverDataSourceBaseUrlString + "/venues/search"
        default:
            return serverDataSourceBaseUrlString + "/venues/search"
        }
    }
    
    func url() -> URL {
        guard let url = URL(string: self.urlString()) else {
            return URL(string: "https://www.google.com")!
        }
        return url
    }
    
    func errorTitle() -> String {
        switch self {
        case .getPlacesOfInterest:
            return Constants.ServerRequestErrorText
        default:
            return Constants.ServerRequestErrorText
        }
    }
}

enum ServerErrorCode: Int {
    // Error codes for error domain ErrorDomainServerError.
    case nilResponse = -101
    
    // MUST be same as on the server
    case parameterError = 101
    case authenticationError = 200
}



