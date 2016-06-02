//
//  CRUDEDeletable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import BrightFutures

protocol CRUDEDeletable: CRUDERequestable {
    var deletePath: String { get }
    func deleteFromServer() -> Future<Okay, NSError>
}

extension CRUDEDeletable {
    var deletePath: String { return CRUDE.baseURL + "\(Self.path)/\(id)" }

    func deleteFromServer() -> Future<Okay, NSError> {
        return CRUDE.requestForSuccess(.DELETE, deletePath)
    }
}
