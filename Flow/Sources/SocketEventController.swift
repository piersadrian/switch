//
//  SocketEventController.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/24/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

public class SocketEventController {
    // MARK: - Private Properties

    // Used to monitor the number of independent `dispatch_source`s watching the
    // underlying socket's file descriptor. Since each source is asynchronous and
    // mutually independent, it's unsafe to `close` a socket until both sources
    // have disconnected. This count should start at the number of sources that
    // will be attached to the file descriptor and decrement each time one
    // disconnects. Once it reaches 0, it's safe to `close` the socket. See:
    // https://mikeash.com/pyblog/friday-qa-2009-12-11-a-gcd-case-study-building-an-http-server.html
    private var refCount: UInt = 0

    private let fd: CFSocketNativeHandle
    private let queue: dispatch_queue_t // NOTE: must be a serial queue

    // MARK: - Internal Properties

    var readSource: DispatchSource?
    var writeSource: DispatchSource?

    // MARK: - Lifecycle

    init(fd: CFSocketNativeHandle, queue: dispatch_queue_t) {
        self.fd = fd
        self.queue = queue
    }

    // MARK: - Public API

    func createSource(type: DispatchSource.Kind, handler: dispatch_block_t, cancelHandler: dispatch_block_t) {
        let dispatchSource = DispatchSource(type: type, fd: self.fd, queue: self.queue, handler: handler)
        self.refCount += 1

        dispatch_source_set_cancel_handler(dispatchSource.source) {
            self.refCount -= 1
            if self.refCount == 0 {
                cancelHandler()
            }
        }

        switch type {
        case .Reader:
            self.readSource = dispatchSource
        case .Writer:
            self.writeSource = dispatchSource
        }
    }
}
