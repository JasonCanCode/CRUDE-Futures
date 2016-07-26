//
//  JSONConvertable.swift
//  CRUDE-Futures
//
//  Created by Jason Welch on 6/2/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import SwiftyJSON

/**
 Identifies any model that can be instantiated by a `JSON` object
 */
public protocol JSONConvertable {
    init(_ json: JSON)
}
