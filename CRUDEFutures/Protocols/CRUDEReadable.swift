//
//  CRUDEReadable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import BrightFutures

/**
 Allows a data model to retrieve a single instance through a GET request to the API.
 */
public protocol CRUDEReadable: CRUDERequestable {
    var readPath: String { get }
    /// The primary key for referencing an instance of this object on a sever. 
    var id: Int { get }
    func readFromServer(queryItems: [String: AnyObject]?) -> Future<Self, NSError>
    static func readFromServerWithId(idNumber: Int, queryItems: [String: AnyObject]?) -> Future<Self, NSError>
}

extension CRUDEReadable {
    /**
     Provide a value if the url for an individual GET varies from the convention of `CRUDE.baseURL + path`. This string will be used instead of `path` for all read requests.

     **Unlike `path`, this will not automatically apply the `baseURL`. Be sure to include it in your value.**
     */
    public var readPath: String { return CRUDE.baseURL + "\(Self.path)/\(id)" }

    /**
     Uses the `id` to retrieve the latest version of itself. Assumes an instance of an entity can be retrieved by providing the id number of the entity in the request path.

     - parameter queryItems: Optional specifications you may send with your request.
     */
    public func readFromServer(queryItems: [String: AnyObject]? = nil) -> Future<Self, NSError> {
        return CRUDE.requestObject(.GET, readPath, parameters: queryItems, key: Self.objectKey) as Future<Self, NSError>
    }

    /**
     Retrieve an entity coorisponding to the `idNumber` provided. Assumes an instance of an entity can be retrieved by providing the id number of the entity in the request path.

     - parameter idNumber:   Identifier for a specific entity
     - parameter queryItems: Optional specifications you may send with your request.
     */
    public static func readFromServerWithId(idNumber: Int, queryItems: [String: AnyObject]? = nil) -> Future<Self, NSError> {
        let path = CRUDE.baseURL + "\(Self.path)/\(idNumber)"
        return CRUDE.requestObject(.GET, path, parameters: queryItems, key: objectKey) as Future<Self, NSError>
    }
}
