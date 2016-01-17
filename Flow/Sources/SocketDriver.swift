//
//  SocketDriver.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/31/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

protocol SocketDriverDelegate {
    func didFinishReadingRequest(driver: SocketDriver, operation: ReadOperation)
    func didFinishWritingResponse(driver: SocketDriver, operation: WriteOperation)
}

public class SocketDriver: IOSocketDelegate {
    // MARK: - Public Properties

    var delegate: SocketDriverDelegate?

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
        socket.delegate = self
    }

    // MARK: - Public API

    public func open() {
        socket.open()
    }

    public func close() {
        socket.events.readSource?.cancel()
        socket.events.writeSource?.cancel()
        socket.close()
    }

    public func readRequest(completion: (NSData) -> Void) -> ReadOperation {
        guard socket.status == .Open else {
            fatalError("socket isn't open for IO; call #open() on IOController first")
        }

        let operation = ReadOperation(completionHandler: completion)

        readQueue.push(operation)

        // if controller isn't working, start work on the serial socket queue
        if readable && !reading {
            dispatch_async(socket.queue) {
                self.dequeueReadOperation()
            }
        }

        return operation
    }

    public func writeResponse(data: NSData, completion: (Void) -> Void) {
        guard socket.status == .Open else {
            fatalError("socket isn't open for IO; call #open() on IOController first")
        }

        let buffer = WriteBuffer(data: data)
        let operation = WriteOperation(buffer: buffer, completionHandler: completion)

        writeQueue.push(operation)

        // if controller isn't working, start work on the serial socket queue
        if writable && !writing {
            dispatch_async(socket.queue) {
                self.dequeueWriteOperation()
            }
        }
    }

    // MARK: - IOSocketDelegate

    func socketCanRead(bytes: Int) {
        readableBytes = bytes
        socket.events.readSource?.pause()
        dequeueReadOperation()
    }

    func socketCanWrite(bytes: Int) {
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
            // TODO: this should throw an IO error
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
            // TODO: this should throw an IO error
            print("caught I/O error: \(error)")
            return false
        }

        return operation.buffer.empty
    }
}
