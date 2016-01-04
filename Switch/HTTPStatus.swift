//
//  HTTPStatus.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/2/16.
//  Copyright © 2016 piersadrian. All rights reserved.
//

import Foundation

enum HTTPStatus: String, CustomStringConvertible {
    case Continue                       = "100 Continue"
    case SwitchingProtocols             = "101 Switching Protocols"
    case Processing                     = "102 Processing"

    case OK                             = "200 OK"
    case Created                        = "201 Created"
    case Accepted                       = "202 Accepted"
    case NonAuthoritativeInformation    = "203 Non-Authoritative Information"
    case NoContent                      = "204 No Content"
    case ResetContent                   = "205 Reset Content"
    case PartialContent                 = "206 Partial Content"

    case MultipleChoices                = "300 Multiple Choices"
    case MovedPermanently               = "301 Moved Permanently"
    case Found                          = "302 Found"
    case SeeOther                       = "303 See Other"
    case NotModified                    = "304 Not Modified"
    case UseProxy                       = "305 Use Proxy"
    case SwitchProxy                    = "306 Switch Proxy"
    case TemporaryRedirect              = "307 Temporary Redirect"
    case PermanentRedirect              = "308 Permanent Redirect"

    case BadRequest                     = "400 Bad Request"
    case Unauthorized                   = "401 Unauthorized"
    case PaymentRequired                = "402 Payment Required"
    case Forbidden                      = "403 Forbidden"
    case NotFound                       = "404 Not Found"
    case MethodNotAllowed               = "405 Method Not Allowed"
    case NotAcceptable                  = "406 Not Acceptable"
    case ProxyAuthenticationRequired    = "407 Proxy Authentication Required"
    case RequestTimeout                 = "408 Request Timeout"
    case Conflict                       = "409 Conflict"
    case Gone                           = "410 Gone"
    case LengthRequired                 = "411 Length Required"
    case PreconditionFailed             = "412 Precondition Failed"
    case PayloadTooLarge                = "413 Payload Too Large"
    case URITooLong                     = "414 URI Too Long"
    case UnsupportedMediaType           = "415 Unsupported Media Type"
    case RangeNotSatisfiable            = "416 Range Not Satisfiable"
    case ExpectationFailed              = "417 Expectation Failed"
    case ImATeapot                      = "418 I'm a teapot"
    case AuthenticationTimeout          = "419 Authentication Timeout"
    case MisdirectedRequest             = "421 Misdirected Request"
    case UnprocessableEntity            = "422 Unprocessable Request"
    case Locked                         = "423 Locked"
    case FailedDependency               = "424 Failed Dependency"
    case UpgradeRequired                = "426 Upgrade Required"
    case PreconditionRequired           = "428 Precondition Required"
    case TooManyRequests                = "429 Too Many Requests"
    case RequestHeaderFieldsTooLarge    = "431 Request Header Fields Too Large"
    case UnavailableForLegalReasons     = "451 Unavailable For Legal Reasons"

    case InternalServerError            = "500 Internal Server Error"
    case NotImplemented                 = "501 Not Implemented"
    case BadGateway                     = "502 Bad Gateway"
    case ServiceUnavailable             = "503 Service Unavailable"
    case GatewayTimeout                 = "504 Gateway Timeout"
    case HTTPVersionNotSupported        = "505 HTTP Version Not Supported"
    case NotExtended                    = "510 Not Extended"
    case NetworkAuthenticationRequired  = "511 Network Authentication Required"
    case UnknownError                   = "520 Unknown Error"

    // MARK: - CustomStringConvertible

    var description: String {
        return "HTTP/1.1 \(rawValue)"
    }
}
