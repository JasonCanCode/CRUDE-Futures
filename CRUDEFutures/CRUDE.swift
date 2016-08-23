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

public typealias HTTPHeaders = [String: String]
public typealias HTTPQueryParameters = [String: AnyObject]?

/// Used to log the request pre-flight
public typealias CRUDERequestLog = (CRUDERequestType, String, HTTPQueryParameters, HTTPHeaders) -> Void
/// A block that receives a request type and a genereic Alamofire Response for debug logging purposes
public typealias CRUDEResponseLog = (Response<AnyObject, NSError>) -> Void

private var _baseURL = ""
private var _headers: HTTPHeaders = [:]
private var _customResponseLogger: CRUDEResponseLog?
internal var _requestLog: CRUDERequestLog?
internal var _responseLog: CRUDEResponseLog? {
    if let logger = _customResponseLogger {
        return logger
    } else if CRUDE.shouldUseDefaultLogger {
        return CRUDE.defaultLogger
    } else {
        return nil
    }
}

public struct CRUDE {

    /// The prefix for the `path` of any model. Remember that setting specific paths, such as `createPath`, will not automatically apply this prefix.
    public static var baseURL: String {
        assert(_baseURL != "", "The base URL needs to be set using CRUDE.config or CRUDE.setBaseURL")
        return _baseURL
    }
    /// The headers sent with every CRUDE API request
    public static var headers: HTTPHeaders {
        return _headers
    }

    public static func setBaseURL(baseURL: String) {
        _baseURL = baseURL
    }

    public static func setHeaders(headers: HTTPHeaders) {
        _headers = headers
    }

    public static func setHeaderValue(value: String?, forKey key: String) {
        _headers[key] = value
    }

    public static func setRequestLoggingBlock(block: CRUDERequestLog) {
        _requestLog = block
    }
    public static func setResponseLoggingBlock(block: CRUDEResponseLog) {
        _customResponseLogger = block
    }
    /// Turn on/off the built in reporting that prints request results to your console.
    public static var shouldUseDefaultLogger = false

    static var errorDomain = "CRUDE-Futures"
    static var errorCode = 600

    /**
     A convenient way to set the baseURL and headers before making any API calls.

     - parameter baseURL:   The prefix for the `path` of any model.
     - parameter headers:   Sent with every CRUDE API request
     - parameter logResult: An optional block used for logging the outcome of a request.
     */
    public static func configure(baseURL: String, headers: HTTPHeaders, responseLoggingBlock logResult: CRUDEResponseLog? = nil) {
        _baseURL = baseURL
        _headers = headers
        _customResponseLogger = logResult
    }

    /**
     The most direct way to sent a request to the API and receiving either a JSON object or an NSError.

     - parameter requestType: `GET`, `POST`, `PUT`, or `DELETE`
     - parameter urlString:   The full url in which to send the request. Directly calling this function will not automatically apply the `baseURL`
     - parameter parameters:  Optionally include query or attribute items.

     - returns: A Future promising a JSON object `onSuccess` or an NSError `onFailure`.
     */
    public static func request(requestType: CRUDERequestType, _ urlString: URLStringConvertible, parameters: HTTPQueryParameters = nil) -> Future<JSON, NSError> {

        let promise = Promise<JSON, NSError>()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        let encoding: ParameterEncoding = requestType != .GET
            ? .JSON
            : .URLEncodedInURL

        _requestLog?(requestType, urlString.URLString, parameters, headers)

        Alamofire.request(requestType.amMethod, urlString, parameters: parameters, encoding: encoding, headers: _headers)
            .validate(statusCode: 200...499)
            .responseJSON { response in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                _responseLog?(response)

                switch response.result {
                case .Success:
                    if let statusCode = response.response?.statusCode where statusCode > 299 {
                        let error = errorFromResponse(response)
                        promise.failure(error)
                    } else {
                        // server can return an empty response, which is ok
                        let json = response.result.value != nil ? JSON(response.result.value!) : nil
                        promise.success(json)
                    }
                case .Failure:
                    let error = errorFromResponse(response)
                    promise.failure(error)
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
    public static func requestObject<T: JSONConvertable>(requestType: CRUDERequestType, _ urlString: URLStringConvertible, parameters: HTTPQueryParameters = nil, key: String? = nil) -> Future<T, NSError> {
        let promise = Promise<T, NSError>()

        request(requestType, urlString, parameters: parameters).onComplete { result in
            guard let json = result.value else {
                promise.failure(result.error ?? NSError(domain: errorDomain, code: CRUDE.errorCode, userInfo: [NSLocalizedDescriptionKey: "No JSON Result"]))
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
    public static func requestObjectsArray<T: JSONConvertable>(requestType: CRUDERequestType, _ urlString: URLStringConvertible, parameters: HTTPQueryParameters = nil, key: String? = nil) -> Future<[T], NSError> {
        let promise = Promise<[T], NSError>()

        request(requestType, urlString, parameters: parameters).onComplete { result in
            guard let json = result.value else {
                promise.failure(result.error ?? NSError(domain: errorDomain, code: CRUDE.errorCode, userInfo: [NSLocalizedDescriptionKey: "No JSON Result"]))
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
    public static func requestForSuccess(requestType: CRUDERequestType, _ urlString: URLStringConvertible, parameters: HTTPQueryParameters = nil) -> Future<Okay, NSError> {
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
        if let error = network.result.error {
            // we already have an error object
            return error
        }
        guard let response = network.response, request = network.request else {
            // we need the network to be right to continue
            return NSError(domain: errorDomain, code: CRUDE.errorCode, userInfo: [NSLocalizedDescriptionKey: "No Request or Response"])
        }

        // default title and detail
        var title = "Error"
        var issue = NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode)

        if let json = network.result.value, let error = JSON(json)["error"].string {
            // there was a single error returned from the server
            issue = error
        } else if let json = network.result.value where JSON(json)["errors"] != nil, let errors = JSON(json)["errors"].array where !errors.isEmpty {
            // there were many errors; use the first one
            title = errors[0]["title"].stringValue
            issue = errors[0]["detail"].stringValue
        } else if let json = network.result.value where JSON(json)["errorsList"] != nil, let errorsList = JSON(json)["errorsList"].array where !errorsList.isEmpty {
            // there were many errors; use the first one
            title = errorsList[0]["title"].stringValue
            issue = errorsList[0]["detail"].stringValue
        }

        var userInfo: [String: AnyObject] = [
            "request": request,
            "response": response,
            "title": title,
            "detail": issue,
            "StatusCode": response.statusCode
        ]
        userInfo[NSLocalizedDescriptionKey] = "\(title): \(issue)"
        return NSError(domain: errorDomain, code: response.statusCode, userInfo: userInfo)
    }

    private static var defaultLogger: CRUDEResponseLog = { network in
        let type = network.request?.HTTPMethod ?? "UNKNOWN"
        var message = "CRUDE request \(type) "
        if let urlString = network.request?.URLString {
            message += "sent to \(urlString) "
        }
        guard let response = network.response where response.statusCode < 300 else {
            message += "FAILED with error: \(CRUDE.errorFromResponse(network))"
            print(message)
            return
        }
        // server can return an empty response, which is ok
        let json = network.result.value != nil ? JSON(network.result.value!) : nil
        message += "successfully received JSON:\n\(json)"
        print(message)
    }

    private static func queryString(params: HTTPQueryParameters) -> String {
        guard let params = params else {
            return ""
        }
        let keyValueStrings: [String] = params.map { "\($0.0)=\($0.1)" }
        return "?\(keyValueStrings.joinWithSeparator("&"))"
    }
}
