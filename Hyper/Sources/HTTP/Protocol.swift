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

public enum HTTPVersion: Float {
    case ZeroNine = 0.9
    case One      = 1.0
    case OneOne   = 1.1

    public init?(versionString: String) {
        let version = Float(versionString) ?? 0
        self.init(rawValue: version)
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
    var request: Request?
    var response: Response?

//    public init(request: Request, response: Response) {
//        self.request = request
//        self.response = response
//    }
}
