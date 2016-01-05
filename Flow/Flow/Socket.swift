//
//  Socket.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/20/15.
//  Copyright © 2015 piersadrian. All rights reserved.
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

class Socket {
    // MARK: - Private Properties

    private var _socket: CFSocket?

    // MARK: - Internal Properties

    var socket: CFSocket {
        if let sock = _socket {
            return sock
        }
        else if let sock = CFSocketCreateWithNative(nil, self.socketFD, 0, nil, nil) {
            self._socket = sock
            return sock
        }
        else {
            fatalError("couldn't create CFSocket from file descriptor \(self.socketFD)")
        }
    }

    var socketFD: Int32
    var events: SocketEventController
    var queue: dispatch_queue_t

    // MARK: - Lifecycle

    init() {
        self.socketFD = -1
        self.queue = dispatch_queue_create("SocketQueue", DISPATCH_QUEUE_SERIAL)
        self.events = SocketEventController(fd: -1, queue: queue)
    }

    convenience init(fd: CFSocketNativeHandle, queue: dispatch_queue_t? = nil) {
        self.init()

        self.socketFD = fd

        if let queue = queue {
            self.queue = queue
            self.events = SocketEventController(fd: socketFD, queue: queue)
        }
    }

    deinit {
        self.close()
    }

    // MARK: - Private API

    private func createAndBind() throws -> CFSocketNativeHandle {
        // Create socket

        guard let socket = CFSocketCreate(nil, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, nil, nil) else {
            throw SocketError(errno: errno)
        }

        let fd = CFSocketGetNative(socket)

        guard fd != -1 else {
            throw SocketError.AlreadyInvalidated
        }


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

        guard CFSocketSetAddress(socket, NSData(bytes: &address, length: sizeof(sockaddr_in))) == .Success else {
            CFSocketInvalidate(socket)
            throw SocketError(errno: errno)
        }

        return fd
    }

    func configure() {
        fatalError("Socket is abstract and must be implemented by concrete subclasses")
    }

    private func invalidateSocket() {
        CFSocketInvalidate(self.socket)
    }

    // MARK: - Public API

    func open() {
        if self.socketFD == -1 {
            dispatch_sync(queue) {
                do {
                    self.socketFD = try self.createAndBind()
                }
                catch {
                    print("couldn't bind socket: \(error)")
                }
            }
        }

        // FIXME: parameterize dispatch queue
        self.events = SocketEventController(fd: self.socketFD, queue: dispatch_get_main_queue())
        configure()
    }

    func close() {
        invalidateSocket()
    }

    // MARK: - CustomStringConvertible

    var description: String {
        return String(self.socket)
    }
}
