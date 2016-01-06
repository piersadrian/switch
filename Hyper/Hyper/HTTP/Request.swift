//
//  Request.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/5/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

public enum HTTPMethod {
    case Get, Post, Put, Patch, Delete, Head, Options

    init?(str: String) {
        let lowercased = str.lowercaseString

        switch lowercased {
        case "get":         self = .Get
        case "post":        self = .Post
        case "put":         self = .Put
        case "patch":       self = .Patch
        case "delete":      self = .Delete
        case "head":        self = .Head
        case "options":     self = .Options

        default:            return nil
        }
    }
}

struct ParsedRequest

public class Request {
    public var body: String
    public var headers: RequestHeaders

    public var originalURL: NSURL
    public var method: HTTPMethod

    // MARK: - Private Properties

    private var length: Int = 0

    init(rawRequest: String) {

    }
}