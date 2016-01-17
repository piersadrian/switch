//
//  Request.swift
//  Flow
//
//  Created by Piers Mainwaring on 1/10/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

public protocol Request: class {
    init(data: NSData)
    var response: Response { get }
}

public protocol Response: class {
    var data: NSData { get }
}

public class RawRequest: Request {
    let data: NSData

    public var response: Response

    public required init(data: NSData) {
        self.data = data
        self.response = RawResponse()
    }
}

public class RawResponse: Response {
    public var data: NSData = NSData()
    public init() {}
}