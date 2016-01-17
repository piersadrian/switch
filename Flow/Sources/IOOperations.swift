//
//  IOOperations.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/1/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

protocol IOOperation: class {}

public class ReadOperation: IOOperation {
    typealias CompletionHandler = (NSData) -> Void

    // MARK: - Internal Properties

    var buffer: ReadBuffer {
        get {
            if let buf = _buffer {
                return buf
            }
            else {
                guard let length = bufferLength else {
                    fatalError("bufferLength must be set in order to create a ReadBuffer lazily")
                }

                let buf = ReadBuffer(length: length)
                self._buffer = buf
                return buf
            }
        }

        set {
            self._buffer = newValue
        }
    }

    var bufferLength: Int?
    let completionHandler: CompletionHandler

    // MARK: - Private Properties

    private var _buffer: ReadBuffer?

    // MARK: - Lifecycle

    init(buffer: ReadBuffer? = nil, completionHandler: CompletionHandler) {
        if let buffer = buffer {
            self._buffer = buffer
            self.bufferLength = buffer.length
        }

        self.completionHandler = completionHandler
    }
}

public class WriteOperation: IOOperation {
    typealias CompletionHandler = (Void) -> Void

    // MARK: - Internal Properties

    var buffer: WriteBuffer
    let completionHandler: CompletionHandler

    // MARK: - Lifecycle

    init(buffer: WriteBuffer, completionHandler: CompletionHandler) {
        self.buffer = buffer
        self.completionHandler = completionHandler
    }
}

class IOOperationQueue<OperationType: IOOperation> {
    // MARK: - Internal Properties

    var operationsPending: Bool {
        return !queue.isEmpty
    }

    // MARK: - Private Properties

    private var queue: [OperationType]

    // MARK: - Lifecycle

    init() {
        self.queue = [OperationType]()
    }

    // MARK: - Internal API

    func peek() -> OperationType? {
        return queue.last
    }

    func push(operation: OperationType) {
        queue.insert(operation, atIndex: 0)
    }

    func pop() -> OperationType? {
        return queue.popLast()
    }
}
