//
//  CRUDEFuturesTests.swift
//  CRUDEFuturesTests
//
//  Created by Jonathan Julian on 8/22/16.
//  Copyright © 2016 Jason Welch. All rights reserved.
//

import XCTest
import BrightFutures
import SwiftyJSON
import Alamofire
import CRUDEFutures

class CRUDEFuturesTests: XCTestCase {

    private let timeoutSeconds = 3.0
    
    override func setUp() {
        super.setUp()
        // Set up for orderup.com/api test requests
        let defaultHeaders: [String: String] = [
            "X-Device-Id": "CRUDE-Futures.test"
        ]
        CRUDE.configure("https://orderup.com/api/", headers: defaultHeaders)
    }

    /// Test a basic 200 response with JSON
    func testBasicSuccess() {
        let asyncExpectation = expectationWithDescription("httpRequest")

        CRUDE.request(.GET, "http://httpbin.org/get").onSuccess { json in
            // success
        }.onFailure { error in
            XCTFail(error.localizedDescription)
        }.onComplete {_ in
            asyncExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(timeoutSeconds, handler: nil)
    }

    /// Test a server failure 500 response
    func testServerFailure() {
        let asyncExpectation = expectationWithDescription("httpRequest")

        CRUDE.request(.GET, "http://httpbin.org/status/500").onSuccess { json in
            XCTFail()
        }.onFailure { error in
            print(error)
            print(error.localizedDescription)
            print(error.localizedFailureReason)

            // AlamoFire returns status code like this
            if let httpStatusCode = error.userInfo["StatusCode"] as? Int {
                print(httpStatusCode)
                XCTAssertEqual(httpStatusCode, 500)
            } else {
                XCTFail("no StatusCode in error object")
            }
        }.onComplete {_ in
            asyncExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(timeoutSeconds, handler: nil)
    }

    /// Test "cannot connect to host" - a non-HTTP error
    func testCannotConnectToServer() {
        let asyncExpectation = expectationWithDescription("httpRequest")

        CRUDE.request(.GET, "http://kaishgerefcjndlss.com/").onSuccess { json in
            XCTFail()
        }.onFailure { error in
            print(error.localizedDescription)
            print(error.localizedFailureReason)
            XCTAssert(error.code != 0)
        }.onComplete {_ in
            asyncExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(timeoutSeconds, handler: nil)
    }

    /// Test success against an orderup.com endpoint
    func testSuccess() {
        let asyncExpectation = expectationWithDescription("httpRequest")

        CRUDE.request(.GET, CRUDE.baseURL + "carts").onSuccess { json in
            XCTAssert(!json.isEmpty)
        }.onFailure { error in
            XCTFail()
        }.onComplete {_ in
            asyncExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(timeoutSeconds, handler: nil)
    }

    /// Test failure against an orderup.com endpoint, make sure the errors are parsed
    func testProcessErrorsFromServer() {
        let asyncExpectation = expectationWithDescription("httpRequest")

        CRUDE.request(.POST, CRUDE.baseURL + "session", parameters: ["email": "user@groupon.com", "password": "secret"]).onSuccess { json in
            XCTFail()
        }.onFailure { error in
            print(error)
            print(error.localizedDescription)
            print(error.localizedFailureReason)

            // AlamoFire returns status code like this, so we do too
            let httpStatusCode = error.userInfo["StatusCode"] as? Int
            XCTAssertNotNil(httpStatusCode)
            print(httpStatusCode)
            XCTAssert(httpStatusCode == 422)

            // CRUDE return of "error"in json response
            let errorMessageTitle = error.userInfo["title"] as? String
            XCTAssertNotNil(errorMessageTitle)
            let errorMessageDetail = error.userInfo["detail"] as? String
            XCTAssertNotNil(errorMessageDetail)

        }.onComplete {_ in
            asyncExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(timeoutSeconds, handler: nil)
    }


}
