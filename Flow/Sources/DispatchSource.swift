//
//  DispatchSource.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/24/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

struct DispatchSource {
    enum Status {
        case Running, Paused, Cancelled
    }

    enum Kind {
        case Reader, Writer

        var dispatchType: dispatch_source_type_t {
            switch self {
            case Reader:
                return DISPATCH_SOURCE_TYPE_READ
            case Writer:
                return DISPATCH_SOURCE_TYPE_WRITE
            }
        }
    }

    // MARK: - Internal Properties

    let source: dispatch_source_t
    let type: Kind
    var status: Status

    // MARK: - Lifecycle

    init(type: Kind, fd: CFSocketNativeHandle, queue: dispatch_queue_t, handler: dispatch_block_t) {
        self.type = type
        self.status = .Paused

        guard let source = dispatch_source_create(type.dispatchType, UInt(fd), 0, queue) else {
            fatalError("couldn't create dispatch_source")
        }

        self.source = source

        dispatch_source_set_event_handler(self.source, handler)
    }

    // MARK: - Public API

    func data() -> UInt {
        return dispatch_source_get_data(self.source)
    }

    mutating func run() {
        guard self.status != .Cancelled else {
            fatalError("DispatchSource is cancelled and cannot be run")
        }

        guard self.status != .Running else {
            fatalError("DispatchSource is already running")
        }

        dispatch_resume(self.source)
        self.status = .Running
    }

    mutating func pause() {
        guard self.status != .Cancelled else {
            fatalError("DispatchSource is cancelled and cannot be paused")
        }

        guard self.status != .Paused else {
            fatalError("DispatchSource is already paused")
        }

        dispatch_suspend(self.source)
        self.status = .Paused
    }

    mutating func cancel() {
        guard self.status != .Cancelled else {
            fatalError("DispatchSource is cancelled and cannot be cancelled again")
        }

        dispatch_source_cancel(self.source)

        // A paused dispatch source will never recognize that it's been cancelled
        // so its cancel handler won't run. This resumes the source so it can process
        // its cancellation. Weird but true.
        if self.status == .Paused {
            dispatch_resume(self.source)
        }

        self.status = .Cancelled
    }
}
