//
//  Socket.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/20/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

enum SocketError: ErrorType {
    case PermissionDenied
    case FileTableOverflow
    case FileLimitReached
    case InsufficientMemory
    case AddressInUse
    case AlreadyBound
    case AddressUnavailable
    case AlreadyInvalidated
    case Error

    init(errno: Int32){
        switch errno {
        case EACCES:
            self = .PermissionDenied
        case EMFILE:
            self = .FileTableOverflow
        case ENFILE:
            self = .FileLimitReached
        case ENOMEM:
            self = .InsufficientMemory
        case EADDRINUSE:
            self = .AddressInUse
        case EINVAL:
            self = .AlreadyBound
        case EADDRNOTAVAIL:
            self = .AddressUnavailable
        default:
            self = .Error
        }
    }
}

enum SocketIOError: ErrorType {
    case EOF
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

enum SocketStatus {
    case Open, Closed
}

public class Socket {
    // MARK: - Internal Properties

    var socketFD: Int32
    var uuid: NSUUID
    var status: SocketStatus = .Closed

    var ioQueue: dispatch_queue_t
    var handlerQueue: dispatch_queue_t

    var readSource: DispatchSource?
    var writeSource: DispatchSource?

    // Used to monitor the number of independent `dispatch_source`s watching the
    // underlying socket's file descriptor. Since each source is asynchronous and
    // mutually independent, it's unsafe to `close` a socket until both sources
    // have disconnected. This count should start at the number of sources that
    // will be attached to the file descriptor and decrement each time one
    // disconnects. Once it reaches 0, it's safe to `close` the socket. See:
    // https://mikeash.com/pyblog/friday-qa-2009-12-11-a-gcd-case-study-building-an-http-server.html
    var dispatchRefCount: Int = 0

    // MARK: - Lifecycle

    init(handlerQueue: dispatch_queue_t) {
        self.socketFD = -1
        self.ioQueue = dispatch_queue_create("com.playfair.socket-io", DISPATCH_QUEUE_SERIAL)
        self.handlerQueue = handlerQueue
        self.uuid = NSUUID()
    }

    init(fd: CFSocketNativeHandle, handlerQueue: dispatch_queue_t, ioQueue: dispatch_queue_t? = nil) {
        self.socketFD = fd
        self.handlerQueue = handlerQueue
        self.uuid = NSUUID()

        if let queue = ioQueue {
            self.ioQueue = queue
        }
        else {
            self.ioQueue = dispatch_queue_create("com.playfair.socket-io", DISPATCH_QUEUE_SERIAL)
        }
    }

    // MARK: - Private API

    private func createAndBind() throws -> CFSocketNativeHandle {
        // Create socket

        let fd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)
        guard fd != -1 else { throw SocketError(errno: errno) }

        // Set SO_REUSEADDR prior to binding socket so we can reattach without waiting for
        // the linger time to expire

        var sockOptionSetting = 1
        guard setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &sockOptionSetting, socklen_t(sizeof(Int))) != -1 else {
            throw SocketError(errno: errno)
        }

        // Bind socket to given address and listen for connections

        var address = sockaddr_in()
        address.sin_len = UInt8(sizeof(sockaddr_in))
        address.sin_family = UInt8(AF_INET)
        address.sin_port = CFSwapInt16HostToBig(4242)
        address.sin_addr.s_addr = 0

        let bindResult = withUnsafePointer(&address) { ptr in
            bind(fd, UnsafePointer<sockaddr>(ptr), socklen_t(sizeof(sockaddr_in)))
        }

        // FIXME: these should throw more specific errors for each operation
        guard bindResult != -1 else { throw SocketError(errno: errno) }
        guard listen(fd, 1024) != -1 else { throw SocketError(errno: errno) }

        return fd
    }

    func configure() {
        fatalError("Socket is abstract and must be implemented by concrete subclasses")
    }

    // MARK: - Internal API

    func createSource(type: dispatch_source_type_t, handler: dispatch_block_t, cancel: dispatch_block_t) -> DispatchSource {
        let dispatchSource = DispatchSource(fd: socketFD, type: type, queue: ioQueue, handler: handler)
        dispatchRefCount += 1

        let fd = self.socketFD
        let uuid = self.uuid

        dispatch_source_set_cancel_handler(dispatchSource.source) { [unowned self] in
            Log.event(fd, uuid: uuid, eventName: "dispatch_source cancel attempt")

            self.dispatchRefCount -= 1
            if self.dispatchRefCount == 0 {
                Log.event(fd, uuid: uuid, eventName: "dispatch_source cancel actual")
                shutdown(self.socketFD, SHUT_RDWR)

                let nullFD = open("/dev/null", O_RDONLY)
                dup2(nullFD, self.socketFD)
                close(nullFD)

                close(self.socketFD)

                cancel()
            }
        }

        return dispatchSource
    }


    // MARK: - Public API

    func attach() {
        if self.socketFD == -1 {
            dispatch_sync(ioQueue) {
                do {
                    self.socketFD = try self.createAndBind()
                }
                catch {
                    fatalError("couldn't bind socket: \(error)")
                }
            }
        }

        configure()
        self.status = .Open
    }

    func release() {
        status = .Closed

        dispatch_async(ioQueue) {
            self.readSource!.cancel()
            self.writeSource!.cancel()
        }
    }
}
