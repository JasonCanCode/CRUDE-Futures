//
//  JSONAttributable.swift
//  CRUDEFutures
//
//  Created by Jason Welch on 6/9/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

/**
 A model that can provide a dictionary of its attributes. This is used to provide parameters for creating and updating entites on your server. 
 
 An adopter only needs to include the `attributes` computed property in order to access `validAttributes`. This provides a dictionary of only attributes that have a value (removing optionals that are nil).
 */
public protocol JSONAttributable {
    /// A dictionary representation of an entity's attributes.
    var attributes: [String: AnyObject?] { get }
    /// Provides a dictionary of only attributes that have a value (removing optionals that are nil).
    var validAttributes: [String: AnyObject] { get }
}

extension JSONAttributable {
    public var validAttributes: [String: AnyObject] {
        var validAttributes: [String: AnyObject] = [:]
        for case let (key, value?) in attributes {
            validAttributes[key] = value
        }
        return validAttributes
    }
}
