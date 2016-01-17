//
//  URI.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/2/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

struct URI {
    static func encode(str: String) -> String {
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
    }

    static func decode(str: String) -> String {
        return str.stringByRemovingPercentEncoding!
    }
}
