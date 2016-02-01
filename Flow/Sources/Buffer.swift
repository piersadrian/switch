//
//  Buffer.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/26/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

// TODO: refactor ReadBuffer/WriteBuffer into a single read-writable Buffer

import Foundation

// A ReadBuffer may concatenate writes, so it needs to be writable after initialization
// Initialize without data -> write chunk -> write chunk ... full
struct ReadBuffer {
    typealias IOHandler = (UnsafeMutablePointer<Void>, Int) -> Int

    // MARK: - Internal Properties

    var length: Int

    var cursor: UnsafeMutablePointer<Void> {
        return _data.mutableBytes.advancedBy(position, limit: endIndex)
    }

    var remainingLength: Int {
        return length - position
    }

    var empty: Bool {
        return position == length
    }

    // MARK: - Private Properties

    private let _data: NSMutableData
    private var position: Int = 0

    private var startIndex: UnsafeMutablePointer<Void>
    private var endIndex: UnsafeMutablePointer<Void>

    // MARK: - Lifecycle

    init(length: Int) {
        guard length > 0 else {
            fatalError("can't create ReadBuffer with zero length")
        }

        self._data = NSMutableData(length: length)!
        self.length = length
        self.startIndex = _data.mutableBytes
        self.endIndex = startIndex.advancedBy(length - 1)
    }

    // MARK: - Internal API

    mutating func withMutablePointer(handler: IOHandler) -> Int {
        guard remainingLength > 0 else {
            fatalError("ReadBuffer is closed")
        }

        let byteCount = handler(cursor, remainingLength)
        advanceCursor(by: byteCount)
        return byteCount
    }

    mutating func advanceCursor(by count: Int) {
        if position + count < length {
            position += count
        }
        else {
            position = length
        }
    }

    mutating func read() -> NSData {
        advanceCursor(by: remainingLength) // prevents any more changes
        return _data as NSData
    }
}

// A WriteBuffer can't change after initialization, but its reading cursor moves
// Initialize with data -> read chunk -> read chunk ... empty
struct WriteBuffer {
    typealias IOHandler = (UnsafePointer<Void>, Int) -> Int

    // MARK: - Internal Properties

    var cursor: UnsafePointer<Void> {
        return data.bytes.advancedBy(position, limit: endIndex)
    }

    var length: Int {
        return data.length
    }

    var remainingLength: Int {
        return length - position
    }

    var empty: Bool {
        return position == length
    }

    // MARK: - Private Properties

    private let data: NSData
    private let endIndex: UnsafePointer<Void>
    private var position: Int = 0

    // MARK: - Lifecycle

    init(data: NSData) {
        guard data.length > 0 else {
            fatalError("can't create buffer with zero length")
        }

        self.data = data
        self.endIndex = data.bytes.advancedBy(data.length - 1)
    }

    // MARK: - Internal API

    mutating func withMutablePointer(handler: IOHandler) -> Int {
        guard remainingLength > 0 else {
            fatalError("WriteBuffer is closed")
        }

        let byteCount = handler(cursor, remainingLength)
        advanceCursor(by: byteCount)
        return byteCount
    }

    mutating func advanceCursor(by count: Int) {
        if position + count < length {
            position += count
        }
        else {
            position = length
        }
    }
}
