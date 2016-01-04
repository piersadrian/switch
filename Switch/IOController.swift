//
//  IOController.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/31/15.
//  Copyright © 2015 piersadrian. All rights reserved.
//

import Foundation

class IOController: IOSocketDelegate {
    // MARK: - Internal Properties

    let socket: IOSocket

    var readable: Bool {
        return readableBytes > 0
    }

    var writable: Bool {
        return writableBytes > 0
    }

    // MARK: - Private Properties

    private var readQueue = IOOperationQueue<ReadOperation>()
    private var writeQueue = IOOperationQueue<WriteOperation>()

    private var readableBytes: Int = 0
    private var writableBytes: Int = 0

    private var reading: Bool = false
    private var writing: Bool = false

    // MARK: - Lifecycle

    init(socket: IOSocket) {
        self.socket = socket
    }

    // MARK: - Internal API

    func readRequest(completion: (NSData) -> Void) {
        let operation = ReadOperation(completionHandler: completion)

        readQueue.push(operation)

        // if controller isn't working, start work
        if readable {
            dequeueReadOperation()
        }
    }

    func writeResponse(data: NSData, completion: (Void) -> Void) {
        let buffer = ReadableBuffer(data: data)
        let operation = WriteOperation(buffer: buffer, completionHandler: completion)

        writeQueue.push(operation)

        // if controller isn't working, start work
        if writable && !writing {
            dequeueWriteOperation()
        }
    }

    func open() {
        socket.delegate = self

        do {
            try socket.open()
        }
        catch {
            fatalError("couldn't open IOSocket. \(error)")
        }
    }

    func close() {
        socket.events.readSource?.cancel()
        socket.events.writeSource?.cancel()
        socket.close()
    }

    // MARK: - IOSocketDelegate

    func socketCanRead(bytes: Int) {
        Log.trace() { "IOSocketDelegate: socketCanRead | \(bytes) bytes | socket FD \(self.socket.socketFD)" }

        readableBytes = bytes
        socket.events.readSource?.pause()
        dequeueReadOperation()
    }

    func debugLog(handler: (Void) -> String) {
        #if DEBUG
            print(handler())
        #endif
    }

    func socketCanWrite(bytes: Int) {
        Log.trace() { "IOSocketDelegate: socketCanWrite | \(bytes) bytes | socket FD \(self.socket.socketFD)" }

        writableBytes = bytes
        socket.events.writeSource?.pause()
        dequeueWriteOperation()
    }

    // MARK: - Private API

    private func dequeueReadOperation() {
        guard socket.events.readSource?.status == .Paused else {
            fatalError("socket read source must be paused to process read operation")
        }

        self.reading = true

        // attempt to dequeue read request
        if let operation = readQueue.peek() {
            operation.bufferLength = readableBytes
            if attemptToCompleteReadOperation(operation) {

                let readData = operation.buffer.read()
                operation.completionHandler(readData)

                readQueue.pop()
                self.reading = false
            }
            else {
                // await notification from socket that there's more to be read
                socket.events.readSource?.run()
            }
        }
        else {
            self.reading = false
        }
    }

    private func dequeueWriteOperation() {
        guard socket.events.writeSource?.status == .Paused else {
            fatalError("socket write source must be paused to process write operation")
        }

        self.writing = true

        // attempt to dequeue write request
        if let operation = writeQueue.peek() {
            if attemptToCompleteWriteOperation(operation) {
                operation.completionHandler()
                writeQueue.pop()
                self.writing = false
            }
            else {
                // await notification from socket that there's more space to write into
                socket.events.writeSource?.run()
            }
        }
        else {
            self.writing = false
        }
    }

    private func attemptToCompleteReadOperation(operation: ReadOperation) -> Bool {
        do {
            try socket.readData(&operation.buffer)
        }
        catch IOError.WouldBlock {
            return false
        }
        catch {
            print("caught I/O error: \(error)")
            return false
        }

        return operation.buffer.empty
    }

    private func attemptToCompleteWriteOperation(operation: WriteOperation) -> Bool {
        do {
            try socket.writeData(&operation.buffer)
        }
        catch IOError.WouldBlock {
            return false
        }
        catch {
            print("caught I/O error: \(error)")
            return false
        }

        return operation.buffer.empty
    }
}
