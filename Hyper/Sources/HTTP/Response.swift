//
//  Response.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/5/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Flow

public class HTTPResponse: Response {
    public let version: HTTPVersion

    public var status: HTTPStatus = .OK

    public var body: [String] = []
    public var headers = ResponseHeaders()

    public var data: NSData

    init(httpVersion: HTTPVersion = .OneOne) {
        self.version = httpVersion
    }
}
