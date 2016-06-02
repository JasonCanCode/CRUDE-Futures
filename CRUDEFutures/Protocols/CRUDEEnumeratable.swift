//
//  CRUDEEnumeratable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import BrightFutures

public protocol CRUDEEnumeratable: CRUDERequestable {
    static var collectionKey: String { get }
    static var enumeratePath: String { get }
    static func enumerateFromServer(params: [String: AnyObject]?) -> Future<[Self], NSError>
}

extension CRUDEEnumeratable {
    public static var enumeratePath: String { return CRUDE.baseURL + Self.path }

    public static func enumerateFromServer(params: [String: AnyObject]? = nil) -> Future<[Self], NSError> {
        return CRUDE.requestObjectsArrayWithKey(collectionKey, .GET, enumeratePath, parameters: params)
    }
}
