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

    weak var connection: HTTPConnection? // replace with protocol for better testing

    // MARK: - Lifecycle

    public init() {
        self.version = .OnePointOne
        self.method  = .Get
        self.path    = ""
        self.headers = RequestHeaders()
        self.body    = ""
        self.originalURL = NSURL()
    }
}

// MARK: - Request Parsing
enum ParseError: ErrorType {
    case UnknownEncoding
    case IncompleteData
    case BadFormat
}

extension HTTPRequest {
    public func parseFromData(data: NSData) throws {
        guard let requestString = String(data: data, encoding: NSISOLatin1StringEncoding) else {
            throw ParseError.UnknownEncoding
        }

        var requestParts = requestString.componentsSeparatedByString(HTTPToken.separator)

        // RFC 2616 §4.1: handle erroneous-but-valid leading CRLFs
        while let leadingLine = requestParts.first {
            if leadingLine.isEmpty {
                requestParts.removeFirst()
            }
            else {
                break
            }
        }

        guard requestParts.count == 2 else {
            throw ParseError.BadFormat
        }

        let envelopeStr = requestParts[0]
        let bodyStr = requestParts[1]

        var scanner = NSScanner(string: envelopeStr)
        scanner.charactersToBeSkipped = nil

        method  = try parseMethod(scanner)
        path    = try parsePath(scanner)
        version = try parseVersion(scanner)
        headers = try parseHeaders(scanner)
        body    = bodyStr

        try validateRequest()
    }

    func validateRequest() throws {
        if version == .OnePointOne {
            // RFC 2616 §14.23: HTTP 1.1 requests must include "Host" header
            guard let host = headers[.Host] else { throw ParseError.BadFormat }
        }
    }

    func parseMethod(scanner: NSScanner) throws -> HTTPMethod {
        // [GET] /index.html HTTP/1.1

        var _method: NSString?
        scanner.scanUpToString(" ", intoString: &_method)
        scanner.scanUpToCharactersFromSet(NSCharacterSet.whitespaceCharacterSet().invertedSet, intoString: nil)

        guard let methodString = _method as? String else {
            fatalError("couldn't parse method")
        }

        guard let method = HTTPMethod(str: methodString) else {
            fatalError("unsupported method")
        }

        return method
    }

    func parsePath(scanner: NSScanner) throws -> String {
        // GET [/index.html] HTTP/1.1

        var _path: NSString?
        scanner.scanUpToString(" ", intoString: &_path)
        scanner.scanUpToCharactersFromSet(NSCharacterSet.alphanumericCharacterSet(), intoString: nil)

        guard let pathString = _path as? String else {
            fatalError("couldn't parse path")
        }

        return pathString
    }

    func parseVersion(scanner: NSScanner) throws -> HTTPVersion {
        // GET /index.html HTTP/[1.1]

        scanner.scanUpToString("/", intoString: nil)
        scanner.scanUpToCharactersFromSet(NSCharacterSet.decimalDigitCharacterSet(), intoString: nil)

        var _version: NSString?
        scanner.scanUpToString(HTTPToken.CRLF, intoString: &_version)
        scanner.scanString(HTTPToken.CRLF, intoString: nil)

        guard let versionString = _version as? String else {
            fatalError("couldn't parse version")
        }

        guard let version = HTTPVersion(versionString: versionString) else {
            fatalError("unsupported version")
        }

        return version
    }

    func parseHeaders(scanner: NSScanner) throws -> RequestHeaders {
        var headers = RequestHeaders()

        while !scanner.atEnd {
            var _headerName: NSString?
            scanner.scanUpToString(":", intoString: &_headerName)
            scanner.scanLocation += 1
            scanner.scanUpToCharactersFromSet(HeaderUtils.headerValueCharacterSet, intoString: nil)

            guard var headerName = _headerName as? String else {
                fatalError("couldn't parse header name")
            }

            var _headerValue: NSString?
            scanner.scanCharactersFromSet(HeaderUtils.headerValueCharacterSet, intoString: &_headerValue)

            if !scanner.atEnd {
                scanner.scanString(HTTPToken.CRLF, intoString: nil)
            }

            guard var headerValue = _headerValue as? String else {
                fatalError("couldn't parse header value")
            }

            headerName = headerName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            headerValue = headerValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())

            headers.setHeader(RequestHeader(name: headerName), value: headerValue)
        }
        
        return headers
    }
}
