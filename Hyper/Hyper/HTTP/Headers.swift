//
//  Headers.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/5/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

public struct RequestHeaders: CustomStringConvertible {
    public var status: HTTPStatus = .OK

    private var _headers: [RequestHeader : String]

    init() {
        self._headers = [:]
    }

    public subscript(header: RequestHeader) -> String? {
        get {
            return _headers[header]
        }

        set {
            if let newValue = newValue {
                setHeader(header, value: newValue)
            }
            else {
                _headers.removeValueForKey(header)
            }
        }
    }

    // MARK: - Private API

    mutating func setHeader(header: RequestHeader, value: String) {
        // FIXME: percent-encode headers
        switch header {
        default:
            _headers[header] = value
        }
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        var headerStrings = _headers.map { "\($0): \($1)" }
        headerStrings.insert(String(status), atIndex: 0)
        return headerStrings.joinWithSeparator("\r\n")
    }
}

public struct ResponseHeaders: CustomStringConvertible {
    public var status: HTTPStatus = .OK

    private var _headers: [ResponseHeader : String]

    init() {
        self._headers = [:]
    }

    public subscript(header: ResponseHeader) -> String? {
        get {
            return _headers[header]
        }

        set {
            if let newValue = newValue {
                setHeader(header, value: newValue)
            }
            else {
                _headers.removeValueForKey(header)
            }
        }
    }

    // MARK: - Private API

    mutating func setHeader(header: ResponseHeader, value: String) {
        // FIXME: percent-encode headers
        switch header {
        default:
            _headers[header] = value
        }
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        var headerStrings = _headers.map { "\($0): \($1)" }
        headerStrings.insert(String(status), atIndex: 0)
        return headerStrings.joinWithSeparator("\r\n")
    }
}

public protocol HTTPHeader: Hashable, CustomStringConvertible {}

public enum RequestHeader: HTTPHeader {
    case Accept
    case AcceptCharset
    case AcceptEncoding
    case AcceptLanguage
    case Authorization
    case CacheControl
    case Connection
    case Cookie
    case ContentLength
    case Date
    case Expect
    case From
    case Host
    case IfMatch
    case IfModifiedSince
    case IfNoneMatch
    case MaxForwards
    case Origin
    case Pragma
    case ProxyAuthentication
    case Range
    case Referer
    case TE
    case UserAgent
    case Upgrade
    case Via
    case Warning

    case Custom(String)

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .Accept:                 return "Accept"
        case .AcceptCharset:          return "Accept-Charset"
        case .AcceptEncoding:         return "Accept-Encoding"
        case .AcceptLanguage:         return "Accept-Language"
        case .Authorization:          return "Authorization"
        case .CacheControl:           return "Cache-Control"
        case .Connection:             return "Connection"
        case .Cookie:                 return "Cookie"
        case .ContentLength:          return "Content-Length"
        case .Date:                   return "Date"
        case .Expect:                 return "Expect"
        case .From:                   return "From"
        case .Host:                   return "Host"
        case .IfMatch:                return "If-Match"
        case .IfModifiedSince:        return "If-Modified-Since"
        case .IfNoneMatch:            return "If-None-Match"
        case .MaxForwards:            return "Max-Forwards"
        case .Origin:                 return "Origin"
        case .Pragma:                 return "Pragma"
        case .ProxyAuthentication:    return "Proxy-Authentication"
        case .Range:                  return "Range"
        case .Referer:                return "Referer"
        case .TE:                     return "TE"
        case .UserAgent:              return "User-Agent"
        case .Upgrade:                return "Upgrade"
        case .Via:                    return "Via"
        case .Warning:                return "Warning"

        case Custom(let name):        return name
        }
    }

    // MARK: - Hashable

    public var hashValue: Int {
        return description.hash
    }
}

public enum ResponseHeader: HTTPHeader {
    case AccessControlAllowOrigin
    case AcceptPatch
    case AcceptRanges
    case Age
    case Allow
    case CacheControl
    case Connection
    case ContentDisposition
    case ContentEncoding
    case ContentLength
    case ContentRange
    case ContentType
    case Date
    case ETag
    case Expires
    case LastModified
    case Link
    case Location
    case P3P
    case PublicKeyPins
    case Pragma
    case RetryAfter
    case Server
    case SetCookie
    case StrictTransportSecurity
    case Trailer
    case TransferEncoding
    case TSV
    case Upgrade
    case Vary
    case Via
    case Warning
    case WWWAuthenticate

    case Custom(String)

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .AccessControlAllowOrigin:  return "Access-Control-Allow-Origin"
        case .AcceptPatch:               return "Accept-Patch"
        case .AcceptRanges:              return "Accept-Ranges"
        case .Age:                       return "Age"
        case .Allow:                     return "Allow"
        case .CacheControl:              return "Cache-Control"
        case .Connection:                return "Connection"
        case .ContentDisposition:        return "Content-Disposition"
        case .ContentEncoding:           return "Content-Encoding"
        case .ContentLength:             return "Content-Length"
        case .ContentRange:              return "Content-Range"
        case .ContentType:               return "Content-Type"
        case .Date:                      return "Date"
        case .ETag:                      return "ETag"
        case .Expires:                   return "Expires"
        case .LastModified:              return "Last-Modified"
        case .Link:                      return "Link"
        case .Location:                  return "Location"
        case .P3P:                       return "P3P"
        case .PublicKeyPins:             return "Public-Key-Pins"
        case .Pragma:                    return "Pragma"
        case .RetryAfter:                return "RetryAfter"
        case .Server:                    return "Server"
        case .SetCookie:                 return "Set-Cookie"
        case .StrictTransportSecurity:   return "Strict-Transport-Security"
        case .Trailer:                   return "Trailer"
        case .TransferEncoding:          return "Transfer-Encoding"
        case .TSV:                       return "TSV"
        case .Upgrade:                   return "Upgrade"
        case .Vary:                      return "Vary"
        case .Via:                       return "Via"
        case .Warning:                   return "Warning"
        case .WWWAuthenticate:           return "WWW-Authenticate"

        case .Custom(let name):          return name
        }
    }

    // MARK: - Hashable

    public var hashValue: Int {
        return description.hash
    }
}

public func ==(lhs: RequestHeader, rhs: RequestHeader) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

public func ==(lhs: ResponseHeader, rhs: ResponseHeader) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
