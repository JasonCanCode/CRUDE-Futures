//
//  CRUDEUpdatable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import BrightFutures

protocol CRUDEUpdatable: CRUDERequestable {
    var attributes: [String: AnyObject] { get }
    var updatePath: String { get }
    func updateOnServer() -> Future<Self, NSError>
    func updateOnServerOkay() -> Future<Okay, NSError>
}

extension CRUDEUpdatable {
    var updatePath: String { return CRUDE.baseURL + "\(Self.path)/\(id)" }

    func updateOnServer() -> Future<Self, NSError> {
        return CRUDE.requestObject(.PUT, updatePath, parameters: attributes)
    }

    func updateOnServerOkay() -> Future<Okay, NSError> {
        return CRUDE.requestForSuccess(.PUT, updatePath)
    }
}