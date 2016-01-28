//
//  IOSocket.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/24/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

public protocol IOSocketDelegate: class {
    func socketDidClose(socket: IOSocket)
}

public class IOSocket: Socket {
    // MARK: - Private Properties

    private var readQueue = IOOperationQueue<ReadOperation>()
    private var writeQueue = IOOperationQueue<WriteOperation>()

    private var readableBytes: Int = 0
    private var writableBytes: Int = 0

    private var readable: Bool {
        return readableBytes > 0
    }

    private var writable: Bool {
        return writableBytes > 0
    }

    private var lock = dispatch_queue_create("com.playfair.socket-lock", DISPATCH_QUEUE_SERIAL)

    private var _reading: Bool = false
    private var reading: Bool {
        get {
            var value = false
            dispatch_sync(lock) { value = self._reading }
            return value
        }
        set {
            dispatch_sync(lock) { self._reading = newValue }
        }
    }

    private var _writing: Bool = false
    private var writing: Bool {
        get {
            var value = false
            dispatch_sync(lock) { value = self._writing }
            return value
        }
        set {
            dispatch_sync(lock) { self._writing = newValue }
        }
    }

    private var readTimerSource: dispatch_source_t?
    private var writeTimerSource: dispatch_source_t?

    // MARK: - Public Properties
    
    public weak var delegate: IOSocketDelegate?

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
            self.delegate?.socketDidClose(self)
        }

        readSource = createSource(DISPATCH_SOURCE_TYPE_READ, handler: readEventHandler, cancel: cancelHandler)
        writeSource = createSource(DISPATCH_SOURCE_TYPE_WRITE, handler: writeEventHandler, cancel: cancelHandler)

        readSource!.run()
        writeSource!.run()
    }

    override func release() {
        if readQueue.operationsPending {
            Log.event(socketFD, uuid: uuid, eventName: "closing socket with pending writes!!!")
        }

        super.release()
    }

    // MARK: - Private API

    private func socketCanRead(bytes: Int) {
        readableBytes = bytes
        readSource!.pause()

        guard bytes > 0 else {
            Log.event(socketFD, uuid: uuid, eventName: "closing socket due to EOF")
            release()
            return
        }

        if !reading {
            dequeueReadOperation()
        }
    }

    private func socketCanWrite(bytes: Int) {
        writableBytes = bytes
        writeSource!.pause()

        if !writing {
            dequeueWriteOperation()
        }
    }

    private func dequeueReadOperation() {
        reading = true

        guard status == .Open else {
            Log.event(socketFD, uuid: uuid, eventName: "can't read: socket is closed")
            return
        }

        guard readSource!.status == .Paused else {
            fatalError("socket read source must be paused to process read operation")
        }

        // attempt to dequeue read request
        if let operation = readQueue.peek() {
            operation.bufferLength = readableBytes // FIXME: this is awful

            if attemptToCompleteReadOperation(operation) {
                dispatch_async(handlerQueue) {
                    operation.completionHandler(operation.buffer.read())
                }

                readQueue.pop()
                Log.event(socketFD, uuid: uuid, eventName: "finished read IO")
            }
            else {
                // mark socket as not reading prior to waking the readSource
                reading = false

                // await notification from socket that there's more to be read
                readSource!.run()
            }
        }

        reading = false
    }

    private func dequeueWriteOperation() {
        writing = true

        guard status == .Open else {
            Log.event(socketFD, uuid: uuid, eventName: "can't write: socket is closed")
            writing = false
            return
        }

        guard writeSource!.status == .Paused else {
            fatalError("socket write source must be paused to process write operation")
        }

        // attempt to dequeue write request
        if let operation = writeQueue.peek() {
            if attemptToCompleteWriteOperation(operation) {
                dispatch_async(handlerQueue) {
                    operation.completionHandler()
                }

                writeQueue.pop()
                Log.event(socketFD, uuid: uuid, eventName: "finished write IO")
            }
            else {
                Log.event(socketFD, uuid: uuid, eventName: "couldn't finish write")

                // mark socket as not writing prior to waking the writeSource
                writing = false

                // await notification from socket that there's more space to write into
                writeSource!.run()
            }
        }

        writing = false
    }

    private func createTimerSource(timeout: NSTimeInterval, handler: dispatch_block_t) -> dispatch_source_t {
        let timestamp = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC)))
        let source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, ioQueue)

        dispatch_source_set_event_handler(source, handler)
        dispatch_source_set_timer(source, timestamp, DISPATCH_TIME_FOREVER, 0)

        return source
    }

    private func triggerReadTimeout() {
        Log.event(socketFD, uuid: uuid, eventName: "read timed out, closing socket")
        release()
    }

    private func triggerWriteTimeout() {
        Log.event(socketFD, uuid: uuid, eventName: "write timed out, closing socket")
        release()
    }

    private func attemptToCompleteReadOperation(operation: ReadOperation) -> Bool {
        let bytesRead: Int

        do {
            // set up read timer
            if operation.timeout > 0 {
                readTimerSource = createTimerSource(operation.timeout) { [unowned self] in
                    self.triggerReadTimeout()
                }
            }

            bytesRead = try readData(&operation.buffer)

            // cancel and clear read timer
            if let source = readTimerSource {
                dispatch_source_cancel(source)
                readTimerSource = nil
            }
        }
        catch SocketIOError.WouldBlock {
            Log.event(socketFD, uuid: uuid, eventName: "read would block")
            return false
        }
        catch SocketIOError.EOF {
            Log.event(socketFD, uuid: uuid, eventName: "releasing on EOF")
            release()
            return false
        }
        catch {
            // TODO: this should throw an IO error
            Log.event(socketFD, uuid: uuid, eventName: "IO error: \(error)")
            return false
        }

        readableBytes -= bytesRead
        return operation.buffer.empty
    }

    private func attemptToCompleteWriteOperation(operation: WriteOperation) -> Bool {
        let bytesWritten: Int

        Log.event(socketFD, uuid: uuid, eventName: "began write")

        do {
            // set up write timer
            if operation.timeout > 0 {
                writeTimerSource = createTimerSource(operation.timeout) { [unowned self] in
                    self.triggerWriteTimeout()
                }
            }

            bytesWritten = try writeData(&operation.buffer)

            // cancel and clear write timer
            if let source = writeTimerSource {
                dispatch_source_cancel(source)
                writeTimerSource = nil
            }
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

        writableBytes -= bytesWritten
        return operation.buffer.empty
    }

    private func readData(inout buffer: ReadBuffer) throws -> Int {
        let fd = socketFD
        if let source = readTimerSource {
            dispatch_resume(source)
        }

        let bytesRead = buffer.withMutablePointer { ptr, length in
            return read(fd, ptr, length)
        }

        switch bytesRead {
        case -1:  throw SocketIOError(errno: errno)
        case 0:   throw SocketIOError.EOF
        default:  return bytesRead
        }
    }

    private func writeData(inout buffer: WriteBuffer) throws -> Int {
        let fd = socketFD
        if let source = writeTimerSource {
            dispatch_resume(source)
        }

        let bytesWritten = buffer.withMutablePointer { ptr, length in
            return write(fd, ptr, length)
        }

        switch bytesWritten {
        case -1:  throw SocketIOError(errno: errno)
        default:  return bytesWritten
        }
    }

    // MARK: - Public API

    public func readRequest(timeout: NSTimeInterval, completion: (NSData) -> Void) {
        dispatch_sync(ioQueue) { [unowned self] in
            guard self.status == .Open else {
                fatalError("socket isn't open for IO; call #open() on IOController first")
            }

            let operation = ReadOperation(timeout: timeout, completionHandler: completion)
            self.readQueue.push(operation)

            // if possible, start reading on the serial IO queue asynchronously
            if self.readable && !self.reading {
                dispatch_async(self.ioQueue) { [unowned self] in
                    self.dequeueReadOperation()
                }
            }
        }
    }

    public func writeResponse(data: NSData, timeout: NSTimeInterval, completion: (Void) -> Void) {
        dispatch_sync(ioQueue) { [unowned self] in
            guard self.status == .Open else {
                fatalError("socket isn't open for IO; call #open() on IOController first")
            }

            let buffer = WriteBuffer(data: data)
            let operation = WriteOperation(buffer: buffer, timeout: timeout, completionHandler: completion)

            self.writeQueue.push(operation)

            // if possible, start writing on the serial IO queue asynchronously
            if self.writable && !self.writing {
                dispatch_async(self.ioQueue) { [unowned self] in
                    self.dequeueWriteOperation()
                }
            }
        }
    }
}
