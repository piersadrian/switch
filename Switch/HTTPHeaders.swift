//
//  Headers.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/2/16.
//  Copyright © 2016 piersadrian. All rights reserved.
//

import Foundation

struct HTTPHeaders: CustomStringConvertible {
    var status: HTTPStatus = .OK

    private var _headers: [HTTPHeaderName : String] = [:]

    init() {
    }

    subscript(name: HTTPHeaderName) -> String? {
        get {
            return _headers[name]
        }

        set {
            if let newValue = newValue {
                _headers.updateValue(newValue, forKey: name) // FIXME: percent-encode headers
            }
            else {
                _headers.removeValueForKey(name)
            }
        }
    }

    // MARK: - CustomStringConvertible

    var description: String {
        var headerStrings = _headers.map { "\($0): \($1)" }
        headerStrings.insert(String(status), atIndex: 0)
        return headerStrings.joinWithSeparator("\r\n")
    }
}
