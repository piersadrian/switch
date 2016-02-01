//
//  Response.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/5/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Flow

public class HTTPResponse {
    public let request: HTTPRequest

    public var version: HTTPVersion {
        return request.version
    }

    public var status: HTTPStatus = .OK
    public var body: [String] = []
    public var headers = ResponseHeaders()

    public var data: NSData = NSData()

    init(request: HTTPRequest) {
        self.request = request
    }
}
