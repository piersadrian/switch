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
    // MARK: - Private Properties

    private var _socket: CFSocket?

    // MARK: - Internal Properties

//    var socket: CFSocket {
//        if let sock = _socket {
//            return sock
//        }
//        else if let sock = CFSocketCreateWithNative(nil, self.socketFD, 0, nil, nil) {
//            self._socket = sock
//            return sock
//        }
//        else {
//            fatalError("couldn't create CFSocket from file descriptor \(self.socketFD)")
//        }
//    }

    var socketFD: Int32
    var queue: dispatch_queue_t
    var status: SocketStatus = .Closed

    var dispatchRefCount: Int = 0
    var readSource: DispatchSource?
    var writeSource: DispatchSource?

    // MARK: - Lifecycle

    init() {
        self.socketFD = -1
        self.queue = dispatch_queue_create("socketQueue", DISPATCH_QUEUE_SERIAL)
    }

    convenience init(fd: CFSocketNativeHandle, queue: dispatch_queue_t? = nil) {
        self.init()

        self.socketFD = fd

        if let queue = queue {
            self.queue = queue
        }
    }

    var deinited = false

    deinit {
//        readSource?.cancel()
//        writeSource?.cancel()
//        self.close()
        self.deinited = true
    }

    // MARK: - Private API

    private func createAndBind() throws -> CFSocketNativeHandle {
        // Create socket

//        guard let socket = CFSocketCreate(nil, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, nil, nil) else {
//            throw SocketError(errno: errno)
//        }
//
//        let fd = CFSocketGetNative(socket)
//
//        guard fd != -1 else {
//            throw SocketError.AlreadyInvalidated
//        }

        let fd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)
        guard fd != -1 else { throw SocketError(errno: errno) }

        // Set SO_REUSEADDR prior to binding socket so we can reattach without waiting for
        // the linger time to expire

        var sockOptionSetting = 1
        guard setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &sockOptionSetting, socklen_t(sizeof(Int))) != -1 else {
            fatalError("couldn't set socket to reuseaddr")
        }

        // Bind socket to given address and listen for connections

        var address = sockaddr_in()
        address.sin_len = UInt8(sizeof(sockaddr_in))
        address.sin_family = UInt8(AF_INET)
        address.sin_port = CFSwapInt16HostToBig(4242)
        address.sin_addr.s_addr = 0

//        guard CFSocketSetAddress(socket, NSData(bytes: &address, length: sizeof(sockaddr_in))) == .Success else {
//            CFSocketInvalidate(socket)
//            throw SocketError(errno: errno)
//        }

        let bindResult = withUnsafePointer(&address) { ptr in
            bind(fd, UnsafePointer<sockaddr>(ptr), socklen_t(sizeof(sockaddr_in)))
        }

        guard bindResult != -1 else { throw SocketError(errno: errno) }
        guard listen(fd, 1024) != -1 else { throw SocketError(errno: errno) }

        return fd
    }

    func configure() {
        fatalError("Socket is abstract and must be implemented by concrete subclasses")
    }

    // MARK: - Internal API


    func createSource(type: dispatch_source_type_t, handler: dispatch_block_t, cancel: dispatch_block_t) -> DispatchSource {
        let dispatchSource = DispatchSource(fd: socketFD, type: type, queue: queue, handler: handler)
        dispatchRefCount += 1

        dispatch_source_set_cancel_handler(dispatchSource.source) { [weak self] in
            guard let sock = self else {
                print("deallocated before cancel...")
                return
            }

            sock.dispatchRefCount -= 1
            if sock.dispatchRefCount == 0 {
                shutdown(sock.socketFD, SHUT_RDWR)

                let nullFD = open("/dev/null", O_RDONLY)
                dup2(nullFD, sock.socketFD)
                close(nullFD)

                close(sock.socketFD)

                cancel()
            }
        }

        return dispatchSource
    }


    // MARK: - Public API

    func attach() {
        if self.socketFD == -1 {
            dispatch_sync(queue) {
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
        readSource!.cancel()
        writeSource!.cancel()
    }
}
