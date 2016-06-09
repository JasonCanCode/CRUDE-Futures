//
//  JSONAttributable.swift
//  CRUDEFutures
//
//  Created by Jason Welch on 6/9/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

public protocol JSONAttributable {
    var attributes: [String: AnyObject?] { get }
    var validAttributes: [String: AnyObject] { get }
}

extension JSONAttributable {
    var validAttributes: [String: AnyObject] {
        var validAttributes: [String: AnyObject] = [:]
        for case let (key, value?) in attributes {
            validAttributes[key] = value
        }
        return validAttributes
    }
}
