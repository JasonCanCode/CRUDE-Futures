//
//  CRUDEEnumeratable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import BrightFutures

public protocol CRUDEEnumeratable: JSONConvertable {
    /// A postfix for the `CRUDE.baseURL` when CRUDE protocol requests are made.
    static var path: String { get }
    static var collectionKey: String? { get }
    static var enumeratePath: String { get }
    static func enumerateFromServer(_ queryItems: [String: AnyObject]?) -> Future<[Self], NSError>
}

extension CRUDEEnumeratable {
    /// Provide a value if the JSON for mapping a collection of entities will be wrapped in a value with a single key.
    public static var collectionKey: String? { return nil }
    /**
     Provide a value if the url for a collective GET varies from the convention of `CRUDE.baseURL + path`. This string will be used instead of `path` for all bulk read requests.

     **Unlike `path`, this will not automatically apply the `baseURL`. Be sure to include it in your value.**
     */
    public static var enumeratePath: String { return CRUDE.baseURL + Self.path }

    /**
     Retrieve a collection of entities.

     - parameter queryItems: Optional specifications you may send with your request.
     */
    public static func enumerateFromServer(_ queryItems: [String: AnyObject]? = nil) -> Future<[Self], NSError> {
        return CRUDE.requestObjectsArray(.GET, enumeratePath, parameters: queryItems, key: collectionKey)
    }
}
