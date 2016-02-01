//
//  RequestParser.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/29/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

enum ParseError: ErrorType {
    case UnknownEncoding
    case MissingHost
    case IncompleteData
    case BadFormat
}

public class HTTPRequestParser {
    var requestData: NSData

    private var _headerValueCharset: NSCharacterSet?
    var headerValueCharacterSet: NSCharacterSet {
        if let charset = _headerValueCharset {
            return charset
        }
        else {
            var charset = NSMutableCharacterSet()
            charset.formUnionWithCharacterSet(NSCharacterSet.alphanumericCharacterSet())
            charset.formUnionWithCharacterSet(NSCharacterSet.symbolCharacterSet())
            charset.formUnionWithCharacterSet(NSCharacterSet.punctuationCharacterSet())
            _headerValueCharset = charset
            return charset
        }
    }

    public init(requestData: NSData) throws {
        self.requestData = requestData
    }

    public func parseRequest() throws -> HTTPRequest {
        guard let requestString = String(data: requestData, encoding: NSUTF8StringEncoding) else {
            throw ParseError.UnknownEncoding
        }

        var requestParts = requestString.componentsSeparatedByString(String(HTTPToken.Separator))

        // RFC 2616, section 4.1: handle erroneous-but-valid leading CRLFs
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

        let envelope = requestParts[0]
        let body = requestParts[1]

        var scanner = NSScanner(string: envelope)
        scanner.charactersToBeSkipped = nil

        var request = HTTPRequest()

        request.method = try parseMethod(scanner, request: request)
        request.path = try parsePath(scanner, request: request)
        request.version = try parseVersion(scanner, request: request)
        request.headers = try parseHeaders(scanner, request: request)

        try validateRequest(request)

        request.body = body

        return request
    }

    func validateRequest(request: HTTPRequest) throws {
        if request.version == .OnePointOne {
            guard let host = request.headers[.Host] else { throw ParseError.MissingHost }
        }
    }

    func parseMethod(scanner: NSScanner, request: HTTPRequest) throws -> HTTPMethod {
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

    func parsePath(scanner: NSScanner, request: HTTPRequest) throws -> String {
        // GET [/index.html] HTTP/1.1

        var _path: NSString?
        scanner.scanUpToString(" ", intoString: &_path)
        scanner.scanUpToCharactersFromSet(NSCharacterSet.alphanumericCharacterSet(), intoString: nil)

        guard let pathString = _path as? String else {
            fatalError("couldn't parse path")
        }

        return pathString
    }

    func parseVersion(scanner: NSScanner, request: HTTPRequest) throws -> HTTPVersion {
        // GET /index.html HTTP/[1.1]

        scanner.scanUpToString("/", intoString: nil)
        scanner.scanUpToCharactersFromSet(NSCharacterSet.decimalDigitCharacterSet(), intoString: nil)

        var _version: NSString?
        scanner.scanUpToString(String(HTTPToken.CRLF), intoString: &_version)
        scanner.scanString(String(HTTPToken.CRLF), intoString: nil)

        guard let versionString = _version as? String else {
            fatalError("couldn't parse version")
        }

        guard let version = HTTPVersion(versionString: versionString) else {
            fatalError("unsupported version")
        }

        return version
    }

    func parseHeaders(scanner: NSScanner, request: HTTPRequest) throws -> RequestHeaders {
        var headers = RequestHeaders()

        while !scanner.atEnd {
            var _headerName: NSString?
            scanner.scanUpToString(":", intoString: &_headerName)
            scanner.scanLocation += 1
            scanner.scanUpToCharactersFromSet(headerValueCharacterSet, intoString: nil)

            guard let headerName = _headerName as? String else {
                fatalError("couldn't parse headername")
            }

            var _headerValue: NSString?
            scanner.scanCharactersFromSet(headerValueCharacterSet, intoString: &_headerValue)

            if !scanner.atEnd {
                scanner.scanString(String(HTTPToken.CRLF), intoString: nil)
            }

            guard let headerValue = _headerValue as? String else {
                fatalError("couldn't parse headervalue")
            }
            
            headers.setHeader(RequestHeader(headerName: headerName), value: headerValue)
        }
        
        return headers
    }
}