//
//  CRUDERequestable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

protocol CRUDERequestable: JSONConvertable {
    var id: Int { get }
    static var path: String { get }
}
