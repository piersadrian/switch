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

    // MARK: - Public Properties
    
    public weak var delegate: IOSocketDelegate?

    // MARK: - Socket Overrides

    deinit {
        print("  @@@ DEINIT: IOSocket - FD \(socketFD) is deinitializing @@@")
    }

    override func close() {
        super.close()
        delegate?.socketDidClose(self)
    }

    override func configure() {
        let readEventHandler = { [weak self] in
            guard let sock = self else { return }
            let byteCount = Int(sock.readSource!.data())
            sock.socketCanRead(byteCount)
        }

        let writeEventHandler = { [weak self] in
            guard let sock = self else { return }
            let byteCount = Int(sock.writeSource!.data())
            sock.socketCanWrite(byteCount)
        }

        createSource(.Reader, handler: readEventHandler, cancelHandler: { [weak self] in self?.close() })
        createSource(.Writer, handler: writeEventHandler, cancelHandler: { [weak self] in self?.close() })

        readSource?.run()
        writeSource?.run()
    }

    // MARK: - Private API

    private func socketCanRead(bytes: Int) {
        readableBytes = bytes
        readSource?.pause()
        dequeueReadOperation()
    }

    private func socketCanWrite(bytes: Int) {
        writableBytes = bytes
        writeSource?.pause()
        dequeueWriteOperation()
    }

    private func dequeueReadOperation() {
        guard readSource?.status != .Cancelled else { return }
        guard readSource?.status == .Paused else {
            fatalError("socket read source must be paused to process read operation")
        }

        guard readable else {
            print("%%%%%%% FD \(socketFD) read EOF, closing socket!")
            close()
            return
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
                readSource?.run()
            }
        }
        else {
            self.reading = false
        }
    }

    private func dequeueWriteOperation() {
        guard readSource?.status != .Cancelled else { return }
        guard writeSource?.status == .Paused else {
            fatalError("socket write source must be paused to process write operation")
        }

        guard writable else {
            return
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
                writeSource?.run()
            }
        }
        else {
            self.writing = false
        }
    }

    private func attemptToCompleteReadOperation(operation: ReadOperation) -> Bool {
        let bytesRead: Int

        do {
            bytesRead = try readData(&operation.buffer)
        }
        catch SocketIOError.WouldBlock {
            return false
        }
        catch SocketIOError.EOF {
            close()
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

    public func readRequest(completion: (NSData) -> Void) {
        guard status == .Open else {
            fatalError("socket isn't open for IO; call #open() on IOController first")
        }

        let operation = ReadOperation(completionHandler: completion)

        readQueue.push(operation)

        // if controller isn't working, start work on the serial socket queue
        if readable && !reading {
            dispatch_async(queue) { [weak self] in
                self?.dequeueReadOperation()
            }
        }
    }

    public func writeResponse(data: NSData, completion: (Void) -> Void) {
        guard status == .Open else {
            fatalError("socket isn't open for IO; call #open() on IOController first")
        }

        let buffer = WriteBuffer(data: data)
        let operation = WriteOperation(buffer: buffer, completionHandler: completion)

        writeQueue.push(operation)

        // if controller isn't working, start work on the serial socket queue
        if writable && !writing {
            dispatch_async(queue) { [weak self] in
                self?.dequeueWriteOperation()
            }
        }
    }
}
