//
//  Environment.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/1/16.
//  Copyright © 2016 piersadrian. All rights reserved.
//

import Foundation

class Request {
    var rawData: NSData = NSData()
    var body: String = ""

    var headers = HTTPHeaders()

    var fullPath: String {
        return String(requestLine.characters.split(" ")[1])
    }

    private var requestLine: String {
        return String(body.characters.split("\r\n").first!)
    }

    init() {
    }
}

class Response {
    var rawData: NSData = NSData()
    var body: String = ""

    var headers = HTTPHeaders()

    init() {
    }
}

class Environment {
    var request: Request
    var response: Response

    init() {
        self.request = Request()
        self.response = Response()
    }
}
