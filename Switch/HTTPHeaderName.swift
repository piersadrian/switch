//
//  Headers.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/2/16.
//  Copyright © 2016 piersadrian. All rights reserved.
//

import Foundation

enum HTTPHeaderName: Hashable, CustomStringConvertible {
    case Allow
    case AcceptRanges
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
    case PublicKeyPins
    case Pragma
    case RetryAfter
    case Server
    case SetCookie
    case StrictTransportSecurity
    case Trailer
    case TransferEncoding
    case Upgrade
    case Vary
    case Via
    case Warning
    case WWWAuthenticate

    case Custom(String)

    // MARK: - CustomStringConvertible

    var description: String {
        switch self {
        case Allow:                     return "Allow"
        case AcceptRanges:              return "Accept-Ranges"
        case CacheControl:              return "Cache-Control"
        case Connection:                return "Connection"
        case ContentDisposition:        return "Content-Disposition"
        case ContentEncoding:           return "Content-Encoding"
        case ContentLength:             return "Content-Length"
        case ContentRange:              return "Content-Range"
        case ContentType:               return "Content-Type"
        case Date:                      return "Date"
        case ETag:                      return "ETag"
        case Expires:                   return "Expires"
        case LastModified:              return "Last-Modified"
        case Link:                      return "Link"
        case Location:                  return "Location"
        case PublicKeyPins:             return "Public-Key-Pins"
        case Pragma:                    return "Pragma"
        case RetryAfter:                return "RetryAfter"
        case Server:                    return "Server"
        case SetCookie:                 return "Set-Cookie"
        case StrictTransportSecurity:   return "Strict-Transport-Security"
        case Trailer:                   return "Trailer"
        case TransferEncoding:          return "Transfer-Encoding"
        case Upgrade:                   return "Upgrade"
        case Vary:                      return "Vary"
        case Via:                       return "Via"
        case Warning:                   return "Warning"
        case WWWAuthenticate:           return "WWW-Authenticate"

        case Custom(let string):        return string
        }
    }

    // MARK: - Hashable

    var hashValue: Int {
        return description.hash
    }
}

func ==(lhs: HTTPHeaderName, rhs: HTTPHeaderName) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
