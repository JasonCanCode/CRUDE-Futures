//
//  CRUDECreatable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import BrightFutures

protocol CRUDECreatable: CRUDERequestable {
    static var createPath: String { get }
    static func createOnServer(attributes: [String: AnyObject]) -> Future<Self, NSError>
    static func createOnServerOkay(attributes: [String: AnyObject]) -> Future<Okay, NSError>
}

extension CRUDECreatable {
    static var createPath: String { return CRUDE.baseURL + path }

    static func createOnServer(attributes: [String: AnyObject]) -> Future<Self, NSError> {
        return CRUDE.requestObject(.POST, createPath, parameters: attributes) as Future<Self, NSError>
    }

    static func createOnServerOkay(attributes: [String: AnyObject]) -> Future<Okay, NSError> {
        return CRUDE.requestForSuccess(.POST, createPath, parameters: attributes)
    }
}