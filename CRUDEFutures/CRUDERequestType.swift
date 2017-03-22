//
//  CRUDERequestType.swift
//  CRUDEFutures
//
//  Created by Jason Welch on 7/19/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import Alamofire

/// An Alamofire Method buffer. Restricts the available Alamofire methods to the four needed for CRUDE, as well as negates the need to import Alamofire in order to use a request function. 
public enum CRUDERequestType: String {
    case GET, POST, PUT, DELETE

    internal var amMethod: Alamofire.HTTPMethod {
        return Alamofire.HTTPMethod(rawValue: self.rawValue)!
    }
}
