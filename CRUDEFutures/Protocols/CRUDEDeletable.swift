//
//  CRUDEDeletable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import BrightFutures

/**
 Allows a data model to delete an existing instance through a DELETE request to the API.
 */
public protocol CRUDEDeletable {
    /// A postfix for the `CRUDE.baseURL` when CRUDE protocol requests are made.
    static var path: String { get }
    /// The primary key for referencing an instance of this object on a sever. 
    var id: Int { get }
    /**
     Provide a value if the url for a DELETE varies from the convention of `CRUDE.baseURL + path`. This string will be used instead of `path` for all deletion requests.

     **Unlike `path`, this will not automatically apply the `baseURL`. Be sure to include it in your value.**
     */
    var deletePath: String { get }
    /// Uses the `id` to delete itself from the remote database. Assumes an instance of an entity can be retrieved by providing the id number of the entity in the request path.
    func deleteFromServer() -> Future<Okay, NSError>
}

extension CRUDEDeletable {
    public var deletePath: String { return CRUDE.baseURL + "\(Self.path)/\(id)" }

    public func deleteFromServer() -> Future<Okay, NSError> {
        return CRUDE.requestForSuccess(.DELETE, deletePath)
    }
}
