//
//  CRUDEUpdatable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import BrightFutures

/**
 Allows a data model to update an existing instance through a PUT request to the API.
 */
public protocol CRUDEUpdatable: CRUDERequestable, JSONAttributable {
    /// The primary key for referencing an instance of this object on a sever. 
    var id: Int { get }
    var updatePath: String { get }
    func updateOnServer(valuedAttributesOnly valuedOnly: Bool) -> Future<Self, NSError>
    func updateOnServerOkay(valuedAttributesOnly valuedOnly: Bool) -> Future<Okay, NSError>
}

extension CRUDEUpdatable {
    /**
     Provide a value if the url for a PUT varies from the convention of `CRUDE.baseURL + path`. This string will be used instead of `path` for all update requests.

     **Unlike `path`, this will not automatically apply the `baseURL`. Be sure to include it in your value.**
     */
    public var updatePath: String { return CRUDE.baseURL + "\(Self.path)/\(id)" }

    /**
     Uses the `id` to update the latest version of itself. Assumes an instance of an entity can be updated by providing the id number of the entity in the request path.

     - parameter valuedOnly: Update on server using `valuedAttributes` instead of `nullifiedAttributes` if true.
     */
    public func updateOnServer(valuedAttributesOnly valuedOnly: Bool = false) -> Future<Self, NSError> {
        let attributes = valuedOnly ? valuedAttributes : nullifiedAttributes
        return CRUDE.requestObject(.PUT, updatePath, parameters: attributes, key: Self.objectKey)
    }

    /**
     A simple update that ignores the result of the request.

     - parameter valuedOnly: Update on server using `valuedAttributes` instead of `nullifiedAttributes` if true.
     */
    public func updateOnServerOkay(valuedAttributesOnly valuedOnly: Bool = false) -> Future<Okay, NSError> {
        let attributes = valuedOnly ? valuedAttributes : nullifiedAttributes
        return CRUDE.requestForSuccess(.PUT, updatePath, parameters: attributes)
    }
}
