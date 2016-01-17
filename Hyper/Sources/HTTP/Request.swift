//
//  Request.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/5/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Flow

public class HTTPRequest: Request {
    public let version: HTTPVersion

    public var method: HTTPMethod
    public var body: String
    public var headers: RequestHeaders

    public var originalURL: NSURL

    public var response: Response = HTTPResponse()

    // MARK: - Private Properties

    private var length: Int = 0

    public required init(data: NSData) {
        self.version = HTTPVersion(rawValue: 1.1)!
        self.body = ""
        self.headers = RequestHeaders()

        self.originalURL = NSURL()
        self.method = .Get
    }
}