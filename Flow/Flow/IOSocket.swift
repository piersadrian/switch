//
//  IOSocket.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/24/15.
//  Copyright © 2015 piersadrian. All rights reserved.
//

import Foundation

protocol IOSocketDelegate {
    func socketCanRead(bytes: Int)
    func socketCanWrite(bytes: Int)
}

enum IOError: ErrorType {
    case WouldBlock
    case Interrupted
    case IOFailed
    case Error

    init(errno: Int32){
        switch errno {
        case EAGAIN, EWOULDBLOCK:
            self = .WouldBlock
        case EINTR:
            self = .Interrupted
        case EIO:
            self = .IOFailed
        default:
            self = .Error
        }
    }
}

class IOSocket: Socket {
    var delegate: IOSocketDelegate?

    override func configure() {
        let readEventHandler = {
            guard let delegate = self.delegate else {
                fatalError("IOSocket must have a delegate")
            }

            let byteCount = Int(self.events.readSource!.data())
            delegate.socketCanRead(byteCount)
        }

        self.events.createSource(.Reader, handler: readEventHandler, cancelHandler: self.close)

        let writeEventHandler = {
            guard let delegate = self.delegate else {
                fatalError("IOSocket must have a delegate")
            }

            let byteCount = Int(self.events.writeSource!.data())
            delegate.socketCanWrite(byteCount)
        }

        self.events.createSource(.Writer, handler: writeEventHandler, cancelHandler: self.close)

        self.events.readSource!.run()
        self.events.writeSource!.run()
    }

    // MARK: - Internal API

    func readData(inout buffer: WritableBuffer) throws {
        let bytesRead = buffer.withPointer { ptr, length in
            return read(self.socketFD, ptr, length)
        }

        switch bytesRead {
        case -1: throw IOError(errno: errno)
        default: break
        }
    }

    func writeData(inout buffer: ReadableBuffer) throws {
        let bytesWritten = buffer.withPointer { ptr, length in
            return write(self.socketFD, ptr, length)
        }

        switch bytesWritten {
        case -1: throw IOError(errno: errno)
        default: break
        }
    }
}
