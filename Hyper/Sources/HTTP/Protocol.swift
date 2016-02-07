//
//  HTTP.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/7/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Flow

enum HTTPToken {
    static let CRLF             = "\r\n"
    static let separator        = "\r\n\r\n"
    static let chunkTerminator  = "0\r\n"
}

public enum HTTPVersion: String, CustomStringConvertible {
    case ZeroPointNine = "0.9"
    case OnePointZero  = "1.0"
    case OnePointOne   = "1.1"

    public init?(versionString: String) {
        self.init(rawValue: versionString)
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        return "HTTP/\(rawValue)"
    }
}

public enum HTTPMethod {
    case Get, Post, Put, Patch, Delete, Head, Options

    init?(str: String) {
        switch str.lowercaseString {
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
