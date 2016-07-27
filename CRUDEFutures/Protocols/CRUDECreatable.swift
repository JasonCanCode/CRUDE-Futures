//
//  CRUDECreatable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import BrightFutures

/**
 Allows a data model to create a new instance through a POST request to the API.
 */
public protocol CRUDECreatable: CRUDERequestable {
    static var createPath: String { get }
    static func createOnServer(attributes: [String: AnyObject]) -> Future<Self, NSError>
    static func createOnServerOkay(attributes: [String: AnyObject]) -> Future<Okay, NSError>
}

extension CRUDECreatable {
    /**
     Provide a value if the url for a POST varies from the convention of `CRUDE.baseURL + path`. This string will be used instead of `path` for all creation requests.

     **Unlike `path`, this will not automatically apply the `baseURL`. Be sure to include it in your value.**
     */
    public static var createPath: String { return CRUDE.baseURL + path }

    /// Provide `attributes` and receive a new data object.
    public static func createOnServer(attributes: [String: AnyObject]) -> Future<Self, NSError> {
        return CRUDE.requestObject(.POST, createPath, parameters: attributes, key: objectKey) as Future<Self, NSError>
    }

    /// A simple entity creation that ignores the result of the request
    public static func createOnServerOkay(attributes: [String: AnyObject]) -> Future<Okay, NSError> {
        return CRUDE.requestForSuccess(.POST, createPath, parameters: attributes)
    }
}
