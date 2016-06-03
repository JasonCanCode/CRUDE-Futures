//
//  CRUDEReadable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import BrightFutures

public protocol CRUDEReadable: CRUDERequestable {
    var readPath: String { get }
    func readFromServer(queryItems: [String: AnyObject]?) -> Future<Self, NSError>
    static func readFromServerWithId(idNumber: Int, queryItems: [String: AnyObject]?) -> Future<Self, NSError>
}

extension CRUDEReadable {
    public var readPath: String { return CRUDE.baseURL + "\(Self.path)/\(id)" }

    public func readFromServer(queryItems: [String: AnyObject]? = nil) -> Future<Self, NSError> {
        return CRUDE.requestObject(.GET, readPath, parameters: queryItems) as Future<Self, NSError>
    }

    public static func readFromServerWithId(idNumber: Int, queryItems: [String: AnyObject]? = nil) -> Future<Self, NSError> {
        let path = CRUDE.baseURL + "\(Self.path)/\(idNumber)"
        return CRUDE.requestObject(.GET, path, parameters: queryItems) as Future<Self, NSError>
    }
}
