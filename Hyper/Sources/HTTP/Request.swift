//
//  Request.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/5/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Flow

public class HTTPRequest {
    // MARK: - Public Properties

    public var version: HTTPVersion
    public var method: HTTPMethod
    public var path: String
    public var headers: RequestHeaders

    public var body: String

    public var originalURL: NSURL

    public required init() {
        self.version = .OnePointOne
        self.method = .Get
        self.path = ""
        self.headers = RequestHeaders()

        self.body = ""

        self.originalURL = NSURL()
    }
}
