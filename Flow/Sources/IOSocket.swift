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

    private var reading: Bool = false
    private var writing: Bool = false

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

    // MARK: - Private API

    private func socketCanRead(bytes: Int) {
        readableBytes = bytes
        readSource!.pause()

        guard bytes > 0 else {
            print("%%%%%%% FD \(socketFD) read EOF from client, closing socket!")
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
        self.reading = true

        guard status == .Open else {
            print("well this is bad")
            return
        }

        guard readSource!.status == .Paused else {
            fatalError("socket read source must be paused to process read operation")
        }

        // attempt to dequeue read request
        if let operation = readQueue.peek() {
            operation.bufferLength = readableBytes // FIXME: this is awful

            if attemptToCompleteReadOperation(operation) {

                // cancel and clear read timer
                if let source = readTimerSource {
                    dispatch_source_cancel(source)
                    readTimerSource = nil
                }

                operation.completionHandler(operation.buffer.read())
                readQueue.pop()
            }
            else {
                // mark socket as not reading prior to waking the readSource
                self.reading = false

                // await notification from socket that there's more to be read
                readSource!.run()
            }
        }

        self.reading = false
    }

    private func dequeueWriteOperation() {
        self.writing = true

        guard status == .Open else {
            print("well this is bad")
            return
        }

        guard writeSource!.status == .Paused else {
            fatalError("socket write source must be paused to process write operation")
        }

        // attempt to dequeue write request
        if let operation = writeQueue.peek() {
            if attemptToCompleteWriteOperation(operation) {
                if let source = writeTimerSource {
                    dispatch_source_cancel(source)
                    writeTimerSource = nil
                }

                operation.completionHandler()
                writeQueue.pop()
            }
            else {
                // mark socket as not writing prior to waking the writeSource
                self.writing = false

                // await notification from socket that there's more space to write into
                writeSource!.run()
            }
        }

        self.writing = false
    }

    private func triggerReadTimeout() {
        print("read timed out")
        release()
    }

    private func triggerWriteTimeout() {
        print("write timed out")
        release()
    }

    private func attemptToCompleteReadOperation(operation: ReadOperation) -> Bool {
        let bytesRead: Int

        do {
            if operation.timeout > 0 {
                let timestamp = dispatch_time(DISPATCH_TIME_NOW, Int64(operation.timeout * 1000) * Int64(NSEC_PER_SEC))
                readTimerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
                dispatch_source_set_event_handler(readTimerSource!) { [weak self] in self?.triggerReadTimeout() }
                dispatch_source_set_timer(readTimerSource!, timestamp, DISPATCH_TIME_FOREVER, 0)
                dispatch_resume(readTimerSource!)
            }

            bytesRead = try readData(&operation.buffer)
        }
        catch SocketIOError.WouldBlock {
            print("wouldblock")
            return false
        }
        catch SocketIOError.EOF {
            print("releasing on EOF")
            release()
            return false
        }
        catch {
            // TODO: this should throw an IO error
            print("caught I/O error, retrying")
            return false
        }

        readableBytes -= bytesRead
        return operation.buffer.empty
    }

    private func attemptToCompleteWriteOperation(operation: WriteOperation) -> Bool {
        let bytesWritten: Int

        do {
            if operation.timeout > 0 {
                writeTimerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
                dispatch_source_set_event_handler(writeTimerSource!) { [weak self] in self?.triggerReadTimeout() }

                let timestamp = dispatch_time(DISPATCH_TIME_NOW, Int64(operation.timeout * 1000) * Int64(NSEC_PER_SEC))
                dispatch_source_set_timer(writeTimerSource!, timestamp, DISPATCH_TIME_FOREVER, 0)
                dispatch_resume(writeTimerSource!)
            }

            bytesWritten = try writeData(&operation.buffer)
        }
        catch SocketIOError.WouldBlock {
            return false
        }
        catch {
            // TODO: this should throw an IO error
            print("caught I/O error, retrying")
            return false
        }

        writableBytes -= bytesWritten
        return operation.buffer.empty
    }

    private func readData(inout buffer: ReadBuffer) throws -> Int {
        let fd = socketFD
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
        guard status == .Open else {
            fatalError("socket isn't open for IO; call #open() on IOController first")
        }

        let operation = ReadOperation(timeout: timeout, completionHandler: completion)

        readQueue.push(operation)

        // if controller isn't working, start work on the serial socket queue
        if readable && !reading {
            dispatch_async(queue) { [unowned self] in
                self.dequeueReadOperation()
            }
        }
    }

    public func writeResponse(data: NSData, timeout: NSTimeInterval, completion: (Void) -> Void) {
        guard status == .Open else {
            fatalError("socket isn't open for IO; call #open() on IOController first")
        }

        let buffer = WriteBuffer(data: data)
        let operation = WriteOperation(buffer: buffer, timeout: timeout, completionHandler: completion)

        writeQueue.push(operation)

        // if controller isn't working, start work on the serial socket queue
        if writable && !writing {
            dispatch_async(queue) { [unowned self] in
                self.dequeueWriteOperation()
            }
        }
    }
}
