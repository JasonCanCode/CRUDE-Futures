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

public typealias CRUDELog = (Alamofire.Method, Response<AnyObject, NSError>) -> Void

private var _baseURL = ""
private var _headers: [String: String] = [:]
private var _logResult: CRUDELog?
private var _useGetParamatersInPath = true

public struct CRUDE {

    public static var baseURL: String {
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

    public static func setRequestLoggingBlock(block: CRUDELog) {
        _logResult = block
    }

    public static func setParamatersShouldBePartOfPathForGet(shouldUse: Bool) {
        _useGetParamatersInPath = shouldUse
    }

    public static func configure(baseURL baseURL: String, headers: [String: String], paramatersShouldBePartOfPathForGet paramsInPath: Bool = true, requestLoggingBlock logResult: CRUDELog? = nil) {
        _baseURL = baseURL
        _headers = headers
        _useGetParamatersInPath = paramsInPath
        _logResult = logResult
    }

    public static func request(method: Alamofire.Method, _ urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil) -> Future<JSON, NSError> {

        let promise = Promise<JSON, NSError>()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        let uri = method != .GET && _useGetParamatersInPath
            ? urlString
            : String(urlString) + queryString(parameters)
        let params = method != .GET && _useGetParamatersInPath
            ? parameters
            : nil

        Alamofire.request(method, uri, parameters: params, encoding: .JSON, headers: _headers)
            .responseJSON { network in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                _logResult?(method, network)

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

    public static func requestObject<T: JSONConvertable>(method: Alamofire.Method, _ urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil) -> Future<T, NSError> {
        let promise = Promise<T, NSError>()

        request(method, urlString, parameters: parameters).onComplete { result in
            guard let json = result.value else {
                promise.failure(result.error ?? NSError(domain: "Unknown Error", code: 600, userInfo: nil))
                return
            }
            let object = T(json)
            promise.success(object)
        }
        return promise.future
    }

    public static func requestObjectsArrayWithKey<T: JSONConvertable>(key: String, _ method: Alamofire.Method, _ urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil) -> Future<[T], NSError> {
        let promise = Promise<[T], NSError>()

        request(method, urlString, parameters: parameters).onComplete { result in
            guard let json = result.value else {
                promise.failure(result.error ?? NSError(domain: "Unknown Error", code: 600, userInfo: nil))
                return
            }
            let objectsArray = json[key].arrayValue.map { T($0) }
            promise.success(objectsArray)
        }
        return promise.future
    }

    public static func requestForSuccess(method: Alamofire.Method, _ urlString: URLStringConvertible, parameters: [String: AnyObject]? = nil) -> Future<Okay, NSError> {
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

    private static func errorFromResponse(network: Response<AnyObject, NSError>, _ parameters: [String: AnyObject]? = nil) -> NSError {
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

// represents an empty (positive) response
public struct Okay {}
