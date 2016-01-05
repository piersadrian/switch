//
//  Headers.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/2/16.
//  Copyright © 2016 piersadrian. All rights reserved.
//

import Foundation

public struct HTTPRequestHeaders: CustomStringConvertible {
    public var status: HTTPStatus = .OK

    private var _headers: [HTTPRequestHeader : String]

    init() {
        self._headers = [:]
    }

    public subscript(header: HTTPRequestHeader) -> String? {
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

    mutating func setHeader(header: HTTPRequestHeader, value: String) {
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

public struct HTTPResponseHeaders: CustomStringConvertible {
    public var status: HTTPStatus = .OK

    private var _headers: [HTTPResponseHeader : String]

    init() {
        self._headers = [:]
    }

    public subscript(header: HTTPResponseHeader) -> String? {
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

    mutating func setHeader(header: HTTPResponseHeader, value: String) {
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
