//
//  Buffer.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/26/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

class Buffer {
    // MARK: - Internal Properties

    var data: NSMutableData

    var length: Int {
        didSet {
            data.length = length
        }
    }

    var remainingLength: Int {
        return data.length - currentPosition
    }

    var currentPosition: Int = 0 {
        willSet {
            if newValue + currentPosition > data.length {
                fatalError("can't set position beyond buffer's length")
            }
        }
    }

    var cursor: UnsafeMutablePointer<Void> {
        return data.mutableBytes.advancedBy(currentPosition)
    }

    var completed: Bool {
        return currentPosition == data.length
    }

    // MARK: - Lifecycle

    init(expectedLength length: Int) {
        self.data = NSMutableData(length: length)!
        self.length = length
    }

    init(data: NSData) {
        self.data = NSMutableData(data: data)
        self.length = data.length
    }
}
