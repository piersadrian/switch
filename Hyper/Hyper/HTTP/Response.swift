//
//  Response.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/5/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

public class Response {
    public var status: HTTPStatus = .OK
    public var body: [String] = []
    public var headers = ResponseHeaders()

    init() {
        
    }
}
