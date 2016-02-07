//
//  IOSocket.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/24/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

public protocol IOSocketDelegate: class {
    func socketDidDetach(socket: IOSocket)
}

public class IOSocket: Socket {
    // TODO: implement readbuffer to collect all available data waiting to be read
    // TODO: switch from lock queue to mutexes?

    // MARK: - Private Properties

    private var lock = dispatch_queue_create("com.playfair.socket-lock", DISPATCH_QUEUE_SERIAL)

    private var readQueue = IOOperationQueue<ReadOperation>()
    private var writeQueue = IOOperationQueue<WriteOperation>()

    private var readableBytes: Int = 0
    private var writableBytes: Int = 0

    private var readable: Bool { return readableBytes > 0 }
    private var writable: Bool { return writableBytes > 0 }

    private var readTimerSource: dispatch_source_t?
    private var writeTimerSource: dispatch_source_t?

    private var readBuffer: Buffer?

    // MARK: - Public Properties
    
    public weak var delegate: IOSocketDelegate?

    // MARK: - Public Static Properties

    public static var defaultReadTimeout: NSTimeInterval  = 2.5 // seconds
    public static var defaultWriteTimeout: NSTimeInterval = 2.5 // seconds

    // MARK: - Socket Overrides

    override func configure() {
        let readEventHandler = { [unowned self] in
            let byteCount = Int(self.readSource!.data())
            self.socketCanRead(byteCount)
        }

        let writeEventHandler = { [unowned self] in
            let byteCount = Int(self.writeSource!.data())
            self.socketCanWrite(byteCount)
        }

        let cancelHandler: dispatch_block_t = { [unowned self] in
            if let delegate = self.delegate {
                delegate.socketDidDetach(self)
            }
            else {
                fatalError("IOSocket detached but no delegate is set! Remember to set IOSocket#delegate")
            }
        }

        readSource = createSource(DISPATCH_SOURCE_TYPE_READ, handler: readEventHandler, cancel: cancelHandler)
        writeSource = createSource(DISPATCH_SOURCE_TYPE_WRITE, handler: writeEventHandler, cancel: cancelHandler)

        readSource!.run()
        writeSource!.run()
    }

    public override func detach(immediately force: Bool = false) {
        status = .Closing

        if force {
            dispatch_async(ioQueue) {
                if self.readQueue.operationsPending {
                    Log.event(self.socketFD, uuid: self.uuid, eventName: "closing socket with pending reads!!!")
                }

                if self.writeQueue.operationsPending {
                    Log.event(self.socketFD, uuid: self.uuid, eventName: "closing socket with pending writes!!!")
                }

                if !self.readQueue.operationsPending && !self.writeQueue.operationsPending {
                    self.status = .Closed

                    if var readSource = self.readSource, var writeSource = self.writeSource {
                        readSource.cancel()
                        writeSource.cancel()
                    }
                    else {
                        self.closeSocket()
                    }
                }
            }
        }
    }

    // MARK: - Private API

    private func socketCanRead(bytes: Int) {
        readSource!.pause()

        Log.event(socketFD, uuid: uuid, eventName: "received message: \(bytes) bytes to read")

        guard bytes > 0 else {
            Log.event(socketFD, uuid: uuid, eventName: "socket read EOF! handle this better")
            return
        }

        readableBytes = bytes
        dequeueReadOperation()
    }

    private func socketCanWrite(bytes: Int) {
        writeSource!.pause()

        Log.event(socketFD, uuid: uuid, eventName: "received message: \(bytes) bytes can be written")

        writableBytes = bytes
        dequeueWriteOperation()
    }

    private func dequeueReadOperation() {
        guard status != .Closed else {
            Log.event(socketFD, uuid: uuid, eventName: "can't read: socket is closed")
            return
        }

        guard readSource!.status == .Paused else {
            fatalError("socket read source must be paused to process read operation")
        }

        guard readable else {
            // app tried to start reading, but we already read everything available and need to see
            // if more has arrived to be read
            Log.event(socketFD, uuid: uuid, eventName: "tried to read: socket has no available data (readable: \(readableBytes), writable: \(writableBytes))")
            readSource!.run()
            return
        }

        guard let operation = readQueue.peek() else {
            // socket tried to start reading, but there are no read operations to process
            Log.event(socketFD, uuid: uuid, eventName: "tried to read: no read operation to process (readable: \(readableBytes), writable: \(writableBytes))")
            return
        }

        // FIXME: needs to be implemented inside ReadOperation
        if operation.buffer.data.length == 0 {
            operation.buffer.data.length = readableBytes
        }

        guard attemptToCompleteReadOperation(operation) else {
            Log.event(socketFD, uuid: uuid, eventName: "couldn't finish read (readable: \(readableBytes), writable: \(writableBytes))")

            // await notification from socket that there's more to be read
            readSource!.run()
            return
        }

        readQueue.pop()
//        Log.event(socketFD, uuid: uuid, eventName: "finished read IO")

        dispatch_async(handlerQueue) {
            operation.completionHandler(operation.buffer.data)
        }

        if status == .Closing && !readQueue.operationsPending && !writeQueue.operationsPending {
            detach(immediately: true)
        }
    }

    private func dequeueWriteOperation() {
        guard status != .Closed else {
            Log.event(socketFD, uuid: uuid, eventName: "can't write: socket is closed")
            return
        }

        guard writeSource!.status == .Paused else {
            fatalError("socket write source must be paused to process write operation")
        }

        guard writable else {
            // app tried to start writing, but we already wrote into all the available space
            // and need to see if space has become available
            Log.event(socketFD, uuid: uuid, eventName: "tried to write: socket has no available space (readable: \(readableBytes), writable: \(writableBytes))")
            writeSource!.run()
            return
        }

        guard let operation = writeQueue.peek() else {
            // socket tried to start writing, but there's no write operation
            Log.event(socketFD, uuid: uuid, eventName: "tried to write: no write operation to process (readable: \(readableBytes), writable: \(writableBytes))")
            return
        }

        guard attemptToCompleteWriteOperation(operation) else {
            Log.event(socketFD, uuid: uuid, eventName: "couldn't finish write (readable: \(readableBytes), writable: \(writableBytes))")

            // await notification from socket that there's more space to write into
            writeSource!.run()
            return
        }

        writeQueue.pop()
//        Log.event(socketFD, uuid: uuid, eventName: "finished write IO")

        dispatch_async(handlerQueue) {
            operation.completionHandler()
        }

        if status == .Closing && !readQueue.operationsPending && !writeQueue.operationsPending {
            detach(immediately: true)
        }
    }

    private func createTimerSource(timeout: NSTimeInterval, handler: dispatch_block_t) -> dispatch_source_t {
        let timestamp = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC)))
        let source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, ioQueue)

        dispatch_source_set_event_handler(source, handler)
        dispatch_source_set_timer(source, timestamp, DISPATCH_TIME_FOREVER, 0)

        return source
    }

    private func triggerReadTimeout() {
        Log.event(socketFD, uuid: uuid, eventName: "read timed out, closing socket (readable: \(self.readableBytes), writable: \(self.writableBytes))")
        detach(immediately: true)
    }

    private func triggerWriteTimeout() {
        Log.event(socketFD, uuid: uuid, eventName: "write timed out, closing socket (readable: \(self.readableBytes), writable: \(self.writableBytes))")
        detach(immediately: true)
    }

    private func attemptToCompleteReadOperation(operation: ReadOperation) -> Bool {
        // ensure the timer source is always cancelled and removed
        defer {
            if let source = readTimerSource { dispatch_source_cancel(source) }
            readTimerSource = nil
        }

        // unspecified read length; attempt to read all data
        if operation.buffer.length == 0 {
            operation.buffer.length = readableBytes
        }

        do {
            Log.event(socketFD, uuid: uuid, eventName: "reading: trying to read \(operation.buffer.remainingLength)")

            let bytesRead = try readFromSocket(intoBuffer: operation.buffer, length: operation.buffer.remainingLength)

            Log.event(socketFD, uuid: uuid, eventName: "reading: successfully read \(bytesRead) (readableBytes now \(readableBytes - bytesRead))")

            readableBytes -= bytesRead
            operation.buffer.currentPosition += bytesRead
        }
        catch SocketIOError.WouldBlock {
            Log.event(socketFD, uuid: uuid, eventName: "read would block")
            return false
        }
        catch SocketIOError.EOF {
            Log.event(socketFD, uuid: uuid, eventName: "EOF, should detach?")
//            detach()
            return false
        }
        catch {
            // TODO: this should throw an IO error
            Log.event(socketFD, uuid: uuid, eventName: "IO error: \(error)")
            return false
        }

        return operation.buffer.completed
    }

    private func attemptToCompleteWriteOperation(operation: WriteOperation) -> Bool {
        // ensure the timer source is always cancelled and removed
        defer {
            if let source = writeTimerSource { dispatch_source_cancel(source) }
            writeTimerSource = nil
        }

        do {
            Log.event(socketFD, uuid: uuid, eventName: "writing: trying to write \(operation.buffer.remainingLength)")

            let bytesWritten = try writeToSocket(fromBuffer: operation.buffer)

            Log.event(socketFD, uuid: uuid, eventName: "writing: successfully wrote \(bytesWritten) (writeableBytes now \(writableBytes - bytesWritten))")

            writableBytes -= bytesWritten
            operation.buffer.currentPosition += bytesWritten
        }
        catch SocketIOError.WouldBlock {
            Log.event(socketFD, uuid: uuid, eventName: "write would block")
            return false
        }
        catch {
            // TODO: this should throw an IO error
            Log.event(socketFD, uuid: uuid, eventName: "IO error: \(error)")
            return false
        }

        return operation.buffer.completed
    }

    private func readFromSocket(intoBuffer buffer: Buffer, length: Int) throws -> Int {
        let bytesRead = read(socketFD, buffer.cursor, length)

        switch bytesRead {
        case -1:  throw SocketIOError(errno: errno)
        case 0:   throw SocketIOError.EOF
        default:  return bytesRead
        }
    }

    private func writeToSocket(fromBuffer buffer: Buffer) throws -> Int {
        let bytesWritten = write(socketFD, buffer.cursor, buffer.remainingLength)

        switch bytesWritten {
        case -1:  throw SocketIOError(errno: errno)
        default:  return bytesWritten
        }
    }

    // MARK: - Public API

    public func readData(length: Int? = nil, timeout: NSTimeInterval = defaultReadTimeout, completion: (NSData) -> Void) {
        dispatch_sync(ioQueue) {
            guard self.status == .Open else {
                fatalError("socket isn't open for IO; call #open() on IOController first")
            }

            let operation = ReadOperation(buffer: Buffer(expectedLength: length ?? self.readableBytes), timeout: timeout, completionHandler: completion)
            self.readQueue.push(operation)

            Log.event(self.socketFD, uuid: self.uuid, eventName: "pushed read operation (readable: \(self.readableBytes), writable: \(self.writableBytes))")

            // set up read timer
            if operation.timeout > 0 {
                self.readTimerSource = self.createTimerSource(operation.timeout) {
                    self.triggerReadTimeout()
                }

                dispatch_resume(self.readTimerSource!)
            }

            // if possible, start reading on the serial IO queue asynchronously
            dispatch_async(self.ioQueue) {
                if self.readSource!.status == .Paused {
                    self.readSource!.run()
                }
            }
        }
    }

    public func writeData(data: NSData, timeout: NSTimeInterval = defaultWriteTimeout, completion: (Void) -> Void) {
        dispatch_sync(ioQueue) {
            guard self.status == .Open else {
                fatalError("socket isn't open for IO; call #open() on IOController first")
            }

            let buffer = Buffer(data: data)
            let operation = WriteOperation(buffer: buffer, timeout: timeout, completionHandler: completion)

            self.writeQueue.push(operation)

            Log.event(self.socketFD, uuid: self.uuid, eventName: "pushed write operation (readable: \(self.readableBytes), writable: \(self.writableBytes))")

            // set up write timer
            if operation.timeout > 0 {
                self.writeTimerSource = self.createTimerSource(operation.timeout) {
                    self.triggerWriteTimeout()
                }

                dispatch_resume(self.writeTimerSource!)
            }

            // if possible, start writing on the serial IO queue asynchronously
            dispatch_async(self.ioQueue) {
                if self.writable {
                    self.dequeueWriteOperation()
                }
            }
        }
    }
}
