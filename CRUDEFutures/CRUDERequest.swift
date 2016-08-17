//
//  CRUDERequest.swift
//  CRUDEFutures
//
//  Created by Jason Welch on 7/19/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import Alamofire
import SwiftyJSON
import BrightFutures

/**
 Provides the functionality of the CRUDE static methods with added control to the request being processed.

 To execute the request, you have three options very similar to the three basic `CRUDE` static functions...

 * `makeRequestForJSON` instead of `request`
 * `makeRequestForObject<T: JSONConvertable>` instead of `requestObject<T: JSONConvertable>`
 * `makeRequestForObjectsArray<T: JSONConvertable>` instead of `requestObjectsArray<T: JSONConvertable>`

 While the request is running, you can use `pauseRequest()` to take a break. Then either `resumeRequest()` later or give up on it and `cancelRequest()`
 */
public struct CRUDERequest {

    public var urlString: URLStringConvertible
    public var parameters: HTTPQueryParameters = nil
    public var headers: [String: String]? = nil
    private var request: Request? = nil

    /**
     Initialize the same way you would use the request function. The `urlString` is a must, with the option to provide `parameters` and/or `headers`.
     
     **You still need to configure CRUDE in your AppDelegate first.**

     - parameter urlString:   The full url in which to send the request. When used, this will NOT automatically apply the `baseURL`
     - parameter parameters:  Optionally include query or attribute items.
     - parameter headers:    Provide if the headers for this request differ from those used by CRUDE. If headers are not provided, the request will default to the headers set when CRUDE was configured.
     */
    public init(urlString: URLStringConvertible, parameters: HTTPQueryParameters = nil, headers: [String: String]? = nil) {
        self.urlString = urlString
        self.parameters = parameters
        self.headers = headers
    }

    /**
     The most direct way to execute a request to the API, resulting in either a JSON object or an NSError.

     - parameter requestType: `GET`, `POST`, `PUT`, or `DELETE`

     - returns: A Future promising a JSON object `onSuccess` or an NSError `onFailure`.
     */
    public mutating func makeRequestForJSON(requestType: CRUDERequestType) -> Future<JSON, NSError> {

        let promise = Promise<JSON, NSError>()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        let encoding: ParameterEncoding = requestType != .GET
            ? .JSON
            : .URLEncodedInURL
        let headers = self.headers ?? CRUDE.headers

        _requestLog?(requestType, urlString.URLString, parameters, headers)

        request = Alamofire.request(requestType.amMethod, urlString, parameters: parameters, encoding: encoding, headers: headers)
        request!.responseJSON { response in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            _responseLog?(response)

            switch response.result {
            case .Success:
                // server can return an empty response, which is ok
                let json = response.result.value != nil ? JSON(response.result.value!) : nil
                promise.success(json)
            case .Failure:
                let error = CRUDE.errorFromResponse(response)
                promise.failure(error)
            }
        }
        return promise.future
    }

    /**
     A convenience function that leverages `makeRequestForJSON` and attempts to create an instance of the object type casted and return it `onSuccess`.

     The best way to call this function is to first  cast it in a local variable:

         let request = makeRequestForObject(.GET) as Future<Person, NSError>
         request().onSuccess { person in
            ...

     - parameter requestType: `GET`, `POST`, `PUT`, or `DELETE`
     - parameter key:         Provide if the JSON for mapping an entity is wrapped in a value with a single key.

     - returns: A Future promising a JSONConvertable object `onSuccess` or an NSError `onFailure`.
     */
    public mutating func makeRequestForObject<T: JSONConvertable>(requestType: CRUDERequestType, key: String? = nil) -> Future<T, NSError> {
        let promise = Promise<T, NSError>()

        makeRequestForJSON(requestType).onComplete { result in
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
     A convenience function that leverages `makeRequestForJSON` and attempts to create an array of type casted objects and return it `onSuccess`.

     The best way to call this function is to first  cast it in a local variable:

         let request = makeRequestForObjectsArray(.GET) as Future<[Person], NSError>
         request().onSuccess { people in
             ...

     - parameter requestType: `GET`, `POST`, `PUT`, or `DELETE`
     - parameter key:         Provide if the JSON for mapping a collection of entites is wrapped in a value with a single key.

     - returns: A Future promising an array of JSONConvertable objects `onSuccess` or an NSError `onFailure`.
     */
    public mutating func makeRequestForObjectsArray<T: JSONConvertable>(requestType: CRUDERequestType, withKey key: String? = nil) -> Future<[T], NSError> {
        let promise = Promise<[T], NSError>()

        makeRequestForJSON(requestType).onComplete { result in
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

    /// Suspend the request before it has finished.
    public func pauseRequest() {
        self.request?.suspend()
    }

    /// Resume a suspended request in progress.
    public func resumeRequest() {
        self.request?.resume()
    }

    /// Cancel a request before it has finished.
    public func cancelRequest() {
        self.request?.cancel()
    }
}
