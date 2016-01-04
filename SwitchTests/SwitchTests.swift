//
//  SwitchTests.swift
//  SwitchTests
//
//  Created by Piers Mainwaring on 1/3/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import XCTest
@testable import Switch

class SwitchTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        class RootEndpoint: Middleware {
            let stack: MiddlewareStack

            required init(stack: MiddlewareStack) {
                self.stack = stack
            }

            func call(env: Environment) {
                if env.request.fullPath == "/" {
                    env.response.headers[.ContentType] = "text/html"
                    env.response.body = "<h1>welcome to the root page</h1><a href=\"/people\">go see the people</a>"
                }

                stack.call(env)
            }
        }

        class ResourceEndpoint: Middleware {
            let stack: MiddlewareStack

            required init(stack: MiddlewareStack) {
                self.stack = stack
            }

            func call(env: Environment) {
                if env.request.fullPath == "/people" {
                    env.response.headers[.ContentType] = "text/html"
                    env.response.body = "<h1>heres the people yo</h1>"
                }
                
                stack.call(env)
            }
        }

        MiddlewareStack.stack = [HTTPIOAdapter.self, RootEndpoint.self, ResourceEndpoint.self]
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let listener = Listener()
        listener.start()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
