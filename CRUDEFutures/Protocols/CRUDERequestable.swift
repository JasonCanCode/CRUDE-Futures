//
//  CRUDERequestable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

public protocol CRUDERequestable: JSONConvertable {
    static var path: String { get }
    static var objectKey: String? { get }
}

extension CRUDERequestable {
    static var objectKey: String? { return nil }
}
