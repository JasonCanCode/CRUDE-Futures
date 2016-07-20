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

public struct CRUDERequest {

    public var urlString: URLStringConvertible
    public var parameters: [String: AnyObject]? = nil
    public var headers: [String: String]? = nil
    private var request: Request? = nil

    public init(urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil, headers: [String: String]? = nil) {
        self.urlString = urlString
        self.parameters = parameters
        self.headers = headers
    }

    public mutating func makeRequestForJSON(requestType: CRUDERequestType) -> Future<JSON, NSError> {

        let promise = Promise<JSON, NSError>()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        let encoding: ParameterEncoding = requestType != .GET
            ? .JSON
            : .URLEncodedInURL
        let headers = self.headers ?? CRUDE.headers

        request = Alamofire.request(requestType.amMethod, urlString, parameters: parameters, encoding: encoding, headers: headers)
        request!.responseJSON { network in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            _logResult?(requestType, network)

            guard let response = network.response else {
                promise.failure(CRUDE.errorFromResponse(network))
                return
            }
            if response.statusCode >= 300 {
                promise.failure(CRUDE.errorFromResponse(network, self.parameters))
            } else {
                // server can return an empty response, which is ok
                let json = network.result.value != nil ? JSON(network.result.value!) : nil
                promise.success(json)
            }
        }
        return promise.future
    }

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

    public func pauseRequest() {
        self.request?.suspend()
    }

    public func resumeRequest() {
        self.request?.resume()
    }

    public func cancelRequest() {
        self.request?.cancel()
    }
}
