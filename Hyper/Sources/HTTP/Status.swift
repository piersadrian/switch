//
//  Status.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/5/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

public enum HTTPStatus: Int, CustomStringConvertible {
    case Continue                       = 100
    case SwitchingProtocols             = 101
    case Processing                     = 102

    case OK                             = 200
    case Created                        = 201
    case Accepted                       = 202
    case NonAuthoritativeInformation    = 203
    case NoContent                      = 204
    case ResetContent                   = 205
    case PartialContent                 = 206

    case MultipleChoices                = 300
    case MovedPermanently               = 301
    case Found                          = 302
    case SeeOther                       = 303
    case NotModified                    = 304
    case UseProxy                       = 305
    case SwitchProxy                    = 306
    case TemporaryRedirect              = 307
    case PermanentRedirect              = 308

    case BadRequest                     = 400
    case Unauthorized                   = 401
    case PaymentRequired                = 402
    case Forbidden                      = 403
    case NotFound                       = 404
    case MethodNotAllowed               = 405
    case NotAcceptable                  = 406
    case ProxyAuthenticationRequired    = 407
    case RequestTimeout                 = 408
    case Conflict                       = 409
    case Gone                           = 410
    case LengthRequired                 = 411
    case PreconditionFailed             = 412
    case PayloadTooLarge                = 413
    case URITooLong                     = 414
    case UnsupportedMediaType           = 415
    case RangeNotSatisfiable            = 416
    case ExpectationFailed              = 417
    case ImATeapot                      = 418
    case AuthenticationTimeout          = 419
    case MisdirectedRequest             = 421
    case UnprocessableEntity            = 422
    case Locked                         = 423
    case FailedDependency               = 424
    case UpgradeRequired                = 426
    case PreconditionRequired           = 428
    case TooManyRequests                = 429
    case RequestHeaderFieldsTooLarge    = 431
    case UnavailableForLegalReasons     = 451

    case InternalServerError            = 500
    case NotImplemented                 = 501
    case BadGateway                     = 502
    case ServiceUnavailable             = 503
    case GatewayTimeout                 = 504
    case HTTPVersionNotSupported        = 505
    case NotExtended                    = 510
    case NetworkAuthenticationRequired  = 511
    case UnknownError                   = 520

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case Continue:                          return "100 Continue"
        case SwitchingProtocols:                return "101 Switching Protocols"
        case Processing:                        return "102 Processing"

        case OK:                                return "200 OK"
        case Created:                           return "201 Created"
        case Accepted:                          return "202 Accepted"
        case NonAuthoritativeInformation:       return "203 Non-Authoritative Information"
        case NoContent:                         return "204 No Content"
        case ResetContent:                      return "205 Reset Content"
        case PartialContent:                    return "206 Partial Content"

        case MultipleChoices:                   return "300 Multiple Choices"
        case MovedPermanently:                  return "301 Moved Permanently"
        case Found:                             return "302 Found"
        case SeeOther:                          return "303 See Other"
        case NotModified:                       return "304 Not Modified"
        case UseProxy:                          return "305 Use Proxy"
        case SwitchProxy:                       return "306 Switch Proxy"
        case TemporaryRedirect:                 return "307 Temporary Redirect"
        case PermanentRedirect:                 return "308 Permanent Redirect"

        case BadRequest:                        return "400 Bad Request"
        case Unauthorized:                      return "401 Unauthorized"
        case PaymentRequired:                   return "402 Payment Required"
        case Forbidden:                         return "403 Forbidden"
        case NotFound:                          return "404 Not Found"
        case MethodNotAllowed:                  return "405 Method Not Allowed"
        case NotAcceptable:                     return "406 Not Acceptable"
        case ProxyAuthenticationRequired:       return "407 Proxy Authentication Required"
        case RequestTimeout:                    return "408 Request Timeout"
        case Conflict:                          return "409 Conflict"
        case Gone:                              return "410 Gone"
        case LengthRequired:                    return "411 Length Required"
        case PreconditionFailed:                return "412 Precondition Failed"
        case PayloadTooLarge:                   return "413 Payload Too Large"
        case URITooLong:                        return "414 URI Too Long"
        case UnsupportedMediaType:              return "415 Unsupported Media Type"
        case RangeNotSatisfiable:               return "416 Range Not Satisfiable"
        case ExpectationFailed:                 return "417 Expectation Failed"
        case ImATeapot:                         return "418 I'm a teapot"
        case AuthenticationTimeout:             return "419 Authentication Timeout"
        case MisdirectedRequest:                return "421 Misdirected Request"
        case UnprocessableEntity:               return "422 Unprocessable Request"
        case Locked:                            return "423 Locked"
        case FailedDependency:                  return "424 Failed Dependency"
        case UpgradeRequired:                   return "426 Upgrade Required"
        case PreconditionRequired:              return "428 Precondition Required"
        case TooManyRequests:                   return "429 Too Many Requests"
        case RequestHeaderFieldsTooLarge:       return "431 Request Header Fields Too Large"
        case UnavailableForLegalReasons:        return "451 Unavailable For Legal Reasons"

        case InternalServerError:               return "500 Internal Server Error"
        case NotImplemented:                    return "501 Not Implemented"
        case BadGateway:                        return "502 Bad Gateway"
        case ServiceUnavailable:                return "503 Service Unavailable"
        case GatewayTimeout:                    return "504 Gateway Timeout"
        case HTTPVersionNotSupported:           return "505 HTTP Version Not Supported"
        case NotExtended:                       return "510 Not Extended"
        case NetworkAuthenticationRequired:     return "511 Network Authentication Required"
        case UnknownError:                      return "520 Unknown Error"
        }
    }
}
