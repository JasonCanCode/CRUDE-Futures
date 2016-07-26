//
//  CRUDEMappable.swift
//  CRUDEFutures
//
//  Created by Jason Welch on 6/6/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

/// An all-in-one protocol for the using all of the CRUDE functions
public protocol CRUDEMappable: CRUDECreatable, CRUDEReadable, CRUDEUpdatable, CRUDEDeletable, CRUDEEnumeratable {}
