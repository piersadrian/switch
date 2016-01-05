//
//  Environment.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/1/16.
//  Copyright © 2016 piersadrian. All rights reserved.
//

import Foundation

public class Request {
    public var rawData: NSData = NSData()
    public var body: String = ""

    public var headers = HTTPRequestHeaders()

    public var fullPath: String {
        return String(requestLine.characters.split(" ")[1])
    }

    private var requestLine: String {
        return String(body.characters.split("\r\n").first!)
    }

    init() {

    }

    init(rawRequest: String) {
        
    }
}

public class Response {
    public var rawData: NSData = NSData()
    public var body: String = ""

    public var headers = HTTPResponseHeaders()

    init() {

    }
}

public class Environment {
    public var request: Request
    public var response: Response

    init() {
        self.request = Request()
        self.response = Response()
    }
}
