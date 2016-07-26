//
//  CRUDERequestable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

/**
 The framework for the five major CRUDE request protocols. 
 
 An adopter must provide a `path string`, which is a postfix for the `CRUDE.baseURL` when requests are made. 
 
 Optionally, provide an `objectKey` value if the JSON for mapping an entity will be wrapped in a value with a single key.
 */
public protocol CRUDERequestable: JSONConvertable {
    /// A postfix for the `CRUDE.baseURL` when CRUDE protocol requests are made.
    static var path: String { get }
    /// Provide a value if the JSON for mapping an entity will be wrapped in a value with a single key.
    static var objectKey: String? { get }
}

extension CRUDERequestable {
    public static var objectKey: String? { return nil }
}
