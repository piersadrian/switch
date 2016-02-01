//
//  HTTP.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/7/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Flow

enum HTTPToken: CustomStringConvertible {
    case CRLF
    case Separator
    case ChunkTerminator

    // MARK: - CustomStringConvertible

    var description: String {
        switch self {
        case .CRLF:                 return "\r\n"
        case .Separator:            return "\r\n\r\n"
        case .ChunkTerminator:      return "0\r\n\r\n"
        }
    }
}

public enum HTTPVersion: String {
    case ZeroPointNine = "0.9"
    case OnePointZero  = "1.0"
    case OnePointOne   = "1.1"

    public init?(versionString: String) {
        self.init(rawValue: versionString)
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


/////////////////////////////////////////////////////////

public class Environment {
    var request: HTTPRequest?
    var response: HTTPResponse?
}
