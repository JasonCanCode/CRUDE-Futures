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

public typealias CRUDELog = (CRUDERequestType, Response<AnyObject, NSError>) -> Void

private var _baseURL = ""
private var _headers: [String: String] = [:]
internal var _logResult: CRUDELog?

public struct CRUDE {

    public static var baseURL: String {
        assert(_baseURL != "", "The base URL needs to be set using CRUDE.config or CRUDE.setBaseURL")
        return _baseURL
    }

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

    public static func configure(baseURL baseURL: String, headers: [String: String], requestLoggingBlock logResult: CRUDELog? = nil) {
        _baseURL = baseURL
        _headers = headers
        _logResult = logResult
    }

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
                    promise.failure(self.errorFromResponse(network, parameters))
                } else {
                    // server can return an empty response, which is ok
                    let json = network.result.value != nil ? JSON(network.result.value!) : nil
                    promise.success(json)
                }
        }
        return promise.future
    }

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

    public static func requestObjectsArrayWithKey<T: JSONConvertable>(key: String?, _ requestType: CRUDERequestType, _ urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil) -> Future<[T], NSError> {
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

    public static func requestForSuccess(method: CRUDERequestType, _ urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil) -> Future<Okay, NSError> {
        let promise = Promise<Okay, NSError>()

        request(.POST, urlString, parameters: parameters).onComplete { result in
            if let error = result.error {
                promise.failure(error)
            } else {
                promise.success(Okay())
            }
        }
        return promise.future
    }

    internal static func errorFromResponse(network: Response<AnyObject, NSError>, _ parameters: [String: AnyObject]? = nil) -> NSError {
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
