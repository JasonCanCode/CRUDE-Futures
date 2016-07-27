//
//  CRUDE.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import Alamofire
import SwiftyJSON
import BrightFutures

/// A block that receives a request type and a genereic Alamofire Response for debug logging purposes
public typealias CRUDELog = (CRUDERequestType, Response<AnyObject, NSError>) -> Void

private var _baseURL = ""
private var _headers: [String: String] = [:]
internal var _logResult: CRUDELog?

public struct CRUDE {

    /// The prefix for the `path` of any model. Remember that setting specific paths, such as `createPath`, will not automatically apply this prefix.
    public static var baseURL: String {
        assert(_baseURL != "", "The base URL needs to be set using CRUDE.config or CRUDE.setBaseURL")
        return _baseURL
    }
    /// The headers sent with every CRUDE API request
    public static var headers: [String: String] {
        return _headers
    }

    public static func setBaseURL(baseURL: String) {
        _baseURL = baseURL
    }

    public static func setHeaders(headers: [String: String]) {
        _headers = headers
    }

    public static func setHeaderValue(value: String?, forKey key: String) {
        _headers[key] = value
    }

    public static func setRequestLoggingBlock(block: CRUDELog) {
        _logResult = block
    }

    /**
     A convenient way to set the baseURL and headers before making any API calls.

     - parameter baseURL:   The prefix for the `path` of any model.
     - parameter headers:   Sent with every CRUDE API request
     - parameter logResult: An optional block used for logging the outcome of a request.
     */
    public static func configure(baseURL baseURL: String, headers: [String: String], requestLoggingBlock logResult: CRUDELog? = nil) {
        _baseURL = baseURL
        _headers = headers
        _logResult = logResult
    }

    /**
     The most direct way to sent a request to the API and receiving either a JSON object or an NSError.

     - parameter requestType: `GET`, `POST`, `PUT`, or `DELETE`
     - parameter urlString:   The full url in which to send the request. Directly calling this function will not automatically apply the `baseURL`
     - parameter parameters:  Optionally include query or attribute items.

     - returns: A Future promising a JSON object `onSuccess` or an NSError `onFailure`.
     */
    public static func request(requestType: CRUDERequestType, _ urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil) -> Future<JSON, NSError> {

        let promise = Promise<JSON, NSError>()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        let encoding: ParameterEncoding = requestType != .GET
            ? .JSON
            : .URLEncodedInURL

        Alamofire.request(requestType.amMethod, urlString, parameters: parameters, encoding: encoding, headers: _headers)
            .responseJSON { network in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                _logResult?(requestType, network)

                guard let response = network.response else {
                    promise.failure(self.errorFromResponse(network))
                    return
                }
                if response.statusCode >= 300 {
                    promise.failure(self.errorFromResponse(network))
                } else {
                    // server can return an empty response, which is ok
                    let json = network.result.value != nil ? JSON(network.result.value!) : nil
                    promise.success(json)
                }
        }
        return promise.future
    }

    /**
     A convenience function that leverages `request` and attempts to create an instance of the object type casted and return it `onSuccess`. 
     
     The best way to call this function is to first  cast it in a local variable:
     
          let request = requestObject(.GET, personURLString) as Future<Person, NSError>
          request().onSuccess { person in
            ...

     - parameter requestType: `GET`, `POST`, `PUT`, or `DELETE`
     - parameter urlString:   The full url in which to send the request. Directly calling this function will not automatically apply the `baseURL`
     - parameter parameters:  Optionally include query or attribute items.
     - parameter key:         Provide if the JSON for mapping an entity is wrapped in a value with a single key.

     - returns: A Future promising a JSONConvertable object `onSuccess` or an NSError `onFailure`.
     */
    public static func requestObject<T: JSONConvertable>(requestType: CRUDERequestType, _ urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil, key: String? = nil) -> Future<T, NSError> {
        let promise = Promise<T, NSError>()

        request(requestType, urlString, parameters: parameters).onComplete { result in
            guard let json = result.value else {
                promise.failure(result.error ?? NSError(domain: "Unknown Error", code: 600, userInfo: nil))
                return
            }
            let object = key != nil
                ? T(json[key!])
                : T(json)
            promise.success(object)
        }
        return promise.future
    }

    /**
     A convenience function that leverages `request` and attempts to create an array of type casted objects and return it `onSuccess`.

     The best way to call this function is to first  cast it in a local variable:

     let request = requestObjectsArray(.GET, personURLString) as Future<[Person], NSError>
     request().onSuccess { people in
     ...

     - parameter requestType: `GET`, `POST`, `PUT`, or `DELETE`
     - parameter urlString:   The full url in which to send the request. Directly calling this function will not automatically apply the `baseURL`
     - parameter parameters:  Optionally include query or attribute items.
     - parameter key:         Provide if the JSON for mapping a collection of entites is wrapped in a value with a single key.

     - returns: A Future promising an array of JSONConvertable objects `onSuccess` or an NSError `onFailure`.
     */
    public static func requestObjectsArray<T: JSONConvertable>(requestType: CRUDERequestType, _ urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil, key: String? = nil) -> Future<[T], NSError> {
        let promise = Promise<[T], NSError>()

        request(requestType, urlString, parameters: parameters).onComplete { result in
            guard let json = result.value else {
                promise.failure(result.error ?? NSError(domain: "Unknown Error", code: 600, userInfo: nil))
                return
            }
            let objectJSON = key != nil
                ? json[key!]
                : json
            let objectsArray = objectJSON.arrayValue.map { T($0) }
            promise.success(objectsArray)
        }
        return promise.future
    }

    /**
     When you want to send a request to the API but you don't care what the response is (as long as it isn't an error)

     - parameter requestType: `GET`, `POST`, `PUT`, or `DELETE`
     - parameter urlString:   The full url in which to send the request. Directly calling this function will not automatically apply the `baseURL`
     - parameter parameters:  Optionally include query or attribute items.

     - returns: A Future promising an `Okay` object `onSuccess` or an NSError  object `onFailure`
     */
    public static func requestForSuccess(requestType: CRUDERequestType, _ urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil) -> Future<Okay, NSError> {
        let promise = Promise<Okay, NSError>()

        request(requestType, urlString, parameters: parameters).onComplete { result in
            if let error = result.error {
                promise.failure(error)
            } else {
                promise.success(Okay())
            }
        }
        return promise.future
    }

    internal static func errorFromResponse(network: Response<AnyObject, NSError>) -> NSError {
        guard let response = network.response, request = network.request else {
            return NSError(domain: "Unknown Error", code: 600, userInfo: nil)
        }

        let statusCodeDescription = NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode)
        var issue = statusCodeDescription
        var title = "Error"

        if let json = network.result.value, let error = JSON(json)["error"].string {
            issue = error
        }
        if let json = network.result.value where JSON(json)["errorsList"] != nil, let errorsList = JSON(json)["errorsList"].array where !errorsList.isEmpty {
            title = errorsList[0]["title"].stringValue
            issue = errorsList[0]["detail"].stringValue
        }
        var debugInfo: [String: AnyObject] = ["request": request, "response": network.response!, "title": title, "detail": issue]
        debugInfo[NSLocalizedDescriptionKey] = "\(title): \(issue)"
        return NSError(domain: issue, code: (network.response?.statusCode ?? -1), userInfo: debugInfo)
    }

    private static func queryString(params: [String: AnyObject]?) -> String {
        guard let params = params else {
            return ""
        }
        let keyValueStrings: [String] = params.map { "\($0.0)=\($0.1)" }
        return "?\(keyValueStrings.joinWithSeparator("&"))"
    }
}
