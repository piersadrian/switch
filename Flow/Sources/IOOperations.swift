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
    let timeout: NSTimeInterval
    let completionHandler: CompletionHandler

    // MARK: - Private Properties

    private var _buffer: ReadBuffer?

    // MARK: - Lifecycle

    init(buffer: ReadBuffer? = nil, timeout: NSTimeInterval, completionHandler: CompletionHandler) {
        if let buffer = buffer {
            self._buffer = buffer
            self.bufferLength = buffer.length
        }

        self.timeout = timeout
        self.completionHandler = completionHandler
    }
}

public class WriteOperation: IOOperation {
    typealias CompletionHandler = (Void) -> Void

    // MARK: - Internal Properties

    var buffer: WriteBuffer
    let timeout: NSTimeInterval
    let completionHandler: CompletionHandler

    // MARK: - Lifecycle

    init(buffer: WriteBuffer, timeout: NSTimeInterval, completionHandler: CompletionHandler) {
        self.buffer = buffer
        self.timeout = timeout
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
    private var lock = dispatch_queue_create("com.playfair.operation-queue-lock", DISPATCH_QUEUE_SERIAL)

    // MARK: - Lifecycle

    init() {
        self.queue = [OperationType]()
    }

    // MARK: - Internal API

    func peek() -> OperationType? {
        var operation: OperationType?
        dispatch_sync(lock) { operation = self.queue.last }
        return operation
    }

    func push(operation: OperationType) {
        dispatch_sync(lock) { self.queue.insert(operation, atIndex: 0) }
    }

    func pop() -> OperationType? {
        var operation: OperationType?
        dispatch_sync(lock) { operation = self.queue.popLast() }
        return operation
    }
}
